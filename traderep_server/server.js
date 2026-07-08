// TradeRep Pro — Railway Backend Server
// Handles: Stripe subscriptions, Twilio SMS, GBP posting
// All sensitive keys live in Railway environment variables — never in the app.

'use strict';
require('dotenv').config();

const express    = require('express');
const cors       = require('cors');
const stripe     = require('stripe')(process.env.STRIPE_SECRET_KEY);
const admin      = require('firebase-admin');
const { OpenAI } = require('openai');

// ── OpenAI client ─────────────────────────────────────────────────────────────
const openai = process.env.OPENAI_API_KEY
  ? new OpenAI({ apiKey: process.env.OPENAI_API_KEY })
  : null;
if (openai) {
  console.log('[OpenAI] Client initialized ✅');
} else {
  console.warn('[OpenAI] OPENAI_API_KEY not set — caption generation disabled');
}

// ── Firebase Admin init ───────────────────────────────────────────────────────
let db = null;
try {
  const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT || '{}');
  if (serviceAccount.project_id) {
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    db = admin.firestore();
    console.log('[Firebase] Initialized ✅ — project:', serviceAccount.project_id);
  } else {
    console.warn('[Firebase] FIREBASE_SERVICE_ACCOUNT not set — Firestore sync disabled');
  }
} catch (e) {
  console.error('[Firebase] Init error:', e.message);
}

// ── Express setup ─────────────────────────────────────────────────────────────
const app = express();

// ── CORS — origin-locked to production app ────────────────────────────────────
// Explicitly allow the Netlify production domain and the Railway server itself.
// ALLOWED_ORIGINS env var lets you add preview/staging domains without code
// changes (comma-separated: https://preview.netlify.app,https://staging.example.com).
const PRODUCTION_ORIGINS = [
  'https://app.tradereppro.com',
  'https://traderep-server-production.up.railway.app',
];
const extraOrigins = (process.env.ALLOWED_ORIGINS || '')
  .split(',')
  .map(o => o.trim())
  .filter(Boolean);
const ALLOWED_ORIGINS = new Set([...PRODUCTION_ORIGINS, ...extraOrigins]);

const corsOptions = {
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, Postman, server-to-server)
    if (!origin) return callback(null, true);
    if (ALLOWED_ORIGINS.has(origin)) return callback(null, true);
    // In development (NODE_ENV !== 'production') allow all origins
    if (process.env.NODE_ENV !== 'production') return callback(null, true);
    callback(new Error(`CORS: origin '${origin}' not allowed`));
  },
  credentials: true,
  optionsSuccessStatus: 200,
};

// IMPORTANT: raw body required for Stripe webhook signature verification.
// Must be registered BEFORE express.json() middleware.
app.use('/stripe-webhook', express.raw({ type: 'application/json' }));
app.use(cors(corsOptions));
app.use(express.json());

// ── Price ID map ──────────────────────────────────────────────────────────────
const PRICE_IDS = {
  starter: process.env.STRIPE_PRICE_STARTER || 'price_1TcTIkCnWFtpnJDSLagxlQCu',
  growth:  process.env.STRIPE_PRICE_GROWTH  || 'price_1TcTJXCnWFtpnJDSXlZpYOs9',
  pro:     process.env.STRIPE_PRICE_PRO     || 'price_1TcTKICnWFtpnJDSmXw4CrWZ',
};

// ─────────────────────────────────────────────────────────────────────────────
// HEALTH CHECK
// ─────────────────────────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  const twilioConfigured = !!(process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN && process.env.TWILIO_PHONE_NUMBER);
  res.json({
    status:            'ok',
    server:            'TradeRep Pro',
    version:           '1.0.0',
    firebase:          db ? 'connected' : 'disabled',
    stripe:            !!process.env.STRIPE_SECRET_KEY,
    twilio:            twilioConfigured,
    twilio_configured: twilioConfigured,   // Flutter SmsService reads this field
    mock_mode:         !twilioConfigured,  // Flutter SmsService reads this field
    messages_sent:     0,                  // Twilio doesn't expose a simple counter
    openai:            !!openai,
    gbp_oauth:         !!(GOOGLE_CLIENT_ID && GOOGLE_CLIENT_SECRET),
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// OPENAI — GENERATE CAPTION
//
// Generates a unique Google Business Profile post caption based on job context.
// Called by the Flutter app when an admin reviews a photo submission.
//
// POST /generate-caption
// Body: {
//   companyName,    // "Smith Roofing"
//   trade,          // "Roofing"
//   serviceArea,    // "Austin, TX"
//   jobType,        // "Roof Replacement"
//   jobDescription, // optional crew note
//   tone,           // "professional" | "friendly" | "bold"  (default: professional)
// }
// Returns: { caption, hashtags }
// ─────────────────────────────────────────────────────────────────────────────
app.post('/generate-caption', async (req, res) => {
  if (!openai) {
    return res.status(503).json({ error: 'OpenAI not configured on server' });
  }

  try {
    const {
      companyName   = '',
      trade         = 'contractor',
      serviceArea   = '',
      jobType       = 'project',
      jobDescription = '',
      tone          = 'professional',
    } = req.body;

    if (!jobType) {
      return res.status(400).json({ error: 'jobType is required' });
    }

    const areaStr = serviceArea ? ` in ${serviceArea}` : '';
    const noteStr = jobDescription ? `\nCrew note: "${jobDescription}"` : '';
    const toneGuide = {
      professional: 'professional and trustworthy — highlight quality and reliability',
      friendly:     'warm and conversational — like a neighbor recommending a trusted contractor',
      bold:         'confident and punchy — short sentences, strong verbs, make them want to call',
    }[tone] || 'professional and trustworthy';

    // Rotate opening styles so posts don't all sound the same
    const openingStyles = [
      'Start with a specific detail about the job or the result (e.g. "40-year-old shingles, gone.")',
      'Start with a question the homeowner was probably asking before hiring (e.g. "Tired of that leaking roof?")',
      'Start with the outcome/transformation (e.g. "Before: cracked tile floor. After: brand new luxury vinyl throughout.")',
      'Start with a behind-the-scenes detail that shows craftsmanship',
      'Start with a short punchy statement about the work or the crew',
    ];
    const openingStyle = openingStyles[Math.floor(Math.random() * openingStyles.length)];

    const prompt = `You are writing a Google Business Profile post for a trade contractor.

Company: ${companyName || 'a local contractor'}
Trade: ${trade}
Location: ${serviceArea || 'local area'}
Job completed: ${jobType}${noteStr}
Tone: ${toneGuide}
Opening style: ${openingStyle}

Write a Google Business Profile post following these rules:
- 3–5 sentences max — no fluff
- Follow the opening style instruction above
- Mention the specific job type naturally
- Include a call to action at the end (vary it — not always "Call us for a free estimate")
- Do NOT use: "thrilled", "delighted", "excited", "proud", "we are pleased"
- Do NOT start with "We just completed" or "We are happy to"
- Sound like the contractor wrote it themselves — real, not corporate
- Location mention is optional — only include if it fits naturally
- Include 1–2 emojis placed naturally (not at the start)

Also generate 6 relevant hashtags (no spaces, each starting with #).
Mix trade-specific tags with local/general ones.

Respond in this exact JSON format:
{
  "caption": "the post text here",
  "hashtags": ["#Tag1", "#Tag2", "#Tag3", "#Tag4", "#Tag5", "#Tag6"]
}`;

    console.log(`[OpenAI] Generating caption — trade: ${trade}, job: ${jobType}, tone: ${tone}`);

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',          // fast and cheap — ~$0.0002 per caption
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.8,              // enough creativity to vary posts
      max_tokens: 400,
      response_format: { type: 'json_object' },
    });

    const raw = completion.choices[0].message.content;
    let parsed;
    try {
      parsed = JSON.parse(raw);
    } catch {
      console.error('[OpenAI] JSON parse error — raw:', raw);
      return res.status(500).json({ error: 'Failed to parse AI response' });
    }

    const caption   = (parsed.caption   || '').trim();
    const hashtags  = Array.isArray(parsed.hashtags) ? parsed.hashtags : [];

    if (!caption) {
      return res.status(500).json({ error: 'Empty caption from AI' });
    }

    console.log(`[OpenAI] Caption generated — ${caption.length} chars, ${hashtags.length} hashtags`);
    res.json({ caption, hashtags });

  } catch (err) {
    console.error('[OpenAI] generate-caption error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// STRIPE — CREATE SUBSCRIPTION
//
// Called by the Flutter app when a user selects a plan.
// 1. Creates or retrieves a Stripe Customer for this company
// 2. Creates a Subscription with a 14-day trial
// 3. Returns the PaymentIntent client_secret so the Flutter payment sheet
//    can collect card details (card is stored but not charged until trial ends)
//
// POST /create-subscription
// Body: { companyId, email, fullName, priceKey }
// priceKey: 'starter' | 'growth' | 'pro'
// ─────────────────────────────────────────────────────────────────────────────
app.post('/create-subscription', async (req, res) => {
  try {
    const { companyId, email, fullName, priceKey } = req.body;

    if (!companyId || !email || !priceKey) {
      return res.status(400).json({ error: 'companyId, email, and priceKey are required' });
    }

    const priceId = PRICE_IDS[priceKey?.toLowerCase()];
    if (!priceId) {
      return res.status(400).json({
        error: `Invalid priceKey: ${priceKey}. Must be starter, growth, or pro.`,
      });
    }

    console.log(`[Stripe] create-subscription — company: ${companyId}, plan: ${priceKey}`);

    // ── 1. Find or create Stripe Customer ─────────────────────────────────────
    let customerId = null;

    // Check Firestore for existing customer ID
    if (db) {
      const companyDoc = await db.collection('companies').doc(companyId).get();
      if (companyDoc.exists) {
        customerId = companyDoc.data()?.stripe_customer_id || null;
      }
    }

    if (!customerId) {
      const customer = await stripe.customers.create({
        email,
        name: fullName || '',
        metadata: { companyId },
      });
      customerId = customer.id;
      console.log(`[Stripe] Created customer: ${customerId}`);

      // Save customer ID to Firestore immediately
      if (db) {
        await db.collection('companies').doc(companyId).update({
          stripe_customer_id: customerId,
        });
      }
    } else {
      console.log(`[Stripe] Reusing customer: ${customerId}`);
    }

    // ── 2. Create Subscription with 14-day trial ──────────────────────────────
    // payment_behavior: 'default_incomplete' means the subscription is created
    // but stays incomplete until the customer confirms their payment method.
    // trial_period_days: 14 — no charge for 14 days.
    // payment_settings.save_default_payment_method: 'on_subscription' — card
    // is saved to the customer for automatic billing after trial.
    const subscription = await stripe.subscriptions.create({
      customer: customerId,
      items: [{ price: priceId }],
      trial_period_days: 14,
      payment_behavior: 'default_incomplete',
      payment_settings: {
        save_default_payment_method: 'on_subscription',
        payment_method_types: ['card'],
      },
      expand: ['latest_invoice.payment_intent'],
      metadata: { companyId, priceKey },
    });

    console.log(`[Stripe] Subscription created: ${subscription.id} — status: ${subscription.status}`);

    // ── 3. Extract client_secret for Flutter payment sheet ────────────────────
    const paymentIntent = subscription.latest_invoice?.payment_intent;
    const clientSecret  = paymentIntent?.client_secret || null;

    // ── 4. Persist subscription to Firestore ──────────────────────────────────
    if (db) {
      const trialEnd = new Date(subscription.trial_end * 1000);
      await db.collection('companies').doc(companyId).update({
        subscription: {
          stripe_subscription_id: subscription.id,
          stripe_customer_id:     customerId,
          price_key:              priceKey,
          status:                 'trialing',
          trial_start:            admin.firestore.Timestamp.fromDate(new Date(subscription.trial_start * 1000)),
          trial_end:              admin.firestore.Timestamp.fromDate(trialEnd),
          current_period_end:     admin.firestore.Timestamp.fromDate(new Date(subscription.current_period_end * 1000)),
          updated_at:             admin.firestore.FieldValue.serverTimestamp(),
        },
      });
      console.log(`[Firestore] Subscription written — trial ends: ${trialEnd.toISOString()}`);
    }

    res.json({
      subscriptionId: subscription.id,
      clientSecret,
      trialEnd: subscription.trial_end,
      status: subscription.status,
    });

  } catch (err) {
    console.error('[Stripe] create-subscription error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// STRIPE — WEBHOOK
//
// Stripe calls this endpoint when subscription events occur.
// Signature verification ensures requests are genuinely from Stripe.
// Updates Firestore so the app always reflects the true subscription state.
//
// POST /stripe-webhook
// ─────────────────────────────────────────────────────────────────────────────
app.post('/stripe-webhook', async (req, res) => {
  const sig     = req.headers['stripe-signature'];
  const secret  = process.env.STRIPE_WEBHOOK_SECRET;

  if (!secret) {
    console.warn('[Webhook] STRIPE_WEBHOOK_SECRET not set — skipping verification');
    return res.status(400).json({ error: 'Webhook secret not configured' });
  }

  let event;
  try {
    event = stripe.webhooks.constructEvent(req.body, sig, secret);
  } catch (err) {
    console.error('[Webhook] Signature verification failed:', err.message);
    return res.status(400).json({ error: `Webhook error: ${err.message}` });
  }

  console.log(`[Webhook] Event received: ${event.type}`);

  try {
    switch (event.type) {

      // ── Trial will end soon (3 days warning) ─────────────────────────────
      case 'customer.subscription.trial_will_end': {
        const sub       = event.data.object;
        const companyId = sub.metadata?.companyId;
        if (companyId && db) {
          await db.collection('companies').doc(companyId).update({
            'subscription.status':    'trial_ending',
            'subscription.updated_at': admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`[Webhook] Trial ending soon — company: ${companyId}`);
        }
        break;
      }

      // ── Subscription updated (trial → active, plan change, etc.) ─────────
      case 'customer.subscription.updated': {
        const sub       = event.data.object;
        const companyId = sub.metadata?.companyId;
        if (companyId && db) {
          await db.collection('companies').doc(companyId).update({
            'subscription.status':             sub.status,
            'subscription.current_period_end': admin.firestore.Timestamp.fromDate(
              new Date(sub.current_period_end * 1000)
            ),
            'subscription.updated_at': admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`[Webhook] Subscription updated — company: ${companyId}, status: ${sub.status}`);
        }
        break;
      }

      // ── Payment succeeded (trial ended, card charged successfully) ────────
      case 'invoice.payment_succeeded': {
        const invoice   = event.data.object;
        const subId     = invoice.subscription;
        if (!subId) break;

        const sub       = await stripe.subscriptions.retrieve(subId);
        const companyId = sub.metadata?.companyId;

        if (companyId && db) {
          await db.collection('companies').doc(companyId).update({
            'subscription.status':             'active',
            'subscription.current_period_end': admin.firestore.Timestamp.fromDate(
              new Date(sub.current_period_end * 1000)
            ),
            'subscription.last_payment':       admin.firestore.FieldValue.serverTimestamp(),
            'subscription.updated_at':         admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`[Webhook] Payment succeeded — company: ${companyId}`);
        }
        break;
      }

      // ── Payment failed (card declined after trial) ────────────────────────
      case 'invoice.payment_failed': {
        const invoice   = event.data.object;
        const subId     = invoice.subscription;
        if (!subId) break;

        const sub       = await stripe.subscriptions.retrieve(subId);
        const companyId = sub.metadata?.companyId;

        if (companyId && db) {
          await db.collection('companies').doc(companyId).update({
            'subscription.status':     'past_due',
            'subscription.updated_at': admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`[Webhook] Payment failed — company: ${companyId}`);
        }
        break;
      }

      // ── Subscription cancelled ────────────────────────────────────────────
      case 'customer.subscription.deleted': {
        const sub       = event.data.object;
        const companyId = sub.metadata?.companyId;
        if (companyId && db) {
          await db.collection('companies').doc(companyId).update({
            'subscription.status':     'canceled',
            'subscription.updated_at': admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`[Webhook] Subscription cancelled — company: ${companyId}`);
        }
        break;
      }

      default:
        console.log(`[Webhook] Unhandled event type: ${event.type}`);
    }
  } catch (err) {
    console.error('[Webhook] Handler error:', err.message);
    // Still return 200 so Stripe doesn't retry — log the error for investigation
  }

  res.json({ received: true });
});

// ─────────────────────────────────────────────────────────────────────────────
// OPENAI — GENERATE SMS
//
// Generates a personalized SMS message for a specific message type.
//
// POST /generate-sms
// Body: {
//   type,          // 'review_request' | 'scheduled' | 'crew_on_way' |
//                  // 'in_progress' | 'completed' | 'thank_you'
//   customerName,  // "John"
//   jobType,       // "Roof Replacement"
//   companyName,   // "Smith Roofing"
//   reviewLink,    // optional — Google review URL
//   crewNote,      // optional — any context the crew added
// }
// Returns: { message }
// ─────────────────────────────────────────────────────────────────────────────
app.post('/generate-sms', async (req, res) => {
  if (!openai) {
    return res.status(503).json({ error: 'OpenAI not configured on server' });
  }

  try {
    const {
      type         = 'review_request',
      customerName = 'there',
      jobType      = 'project',
      companyName  = 'our company',
      reviewLink   = '',
      crewNote     = '',
    } = req.body;

    const typeDescriptions = {
      review_request: 'asking the customer to leave a Google review now that the job is done',
      scheduled:      'letting the customer know their job is scheduled and we\'ll reach out before we come',
      crew_on_way:    'telling the customer the crew just left and is on the way to their property',
      in_progress:    'letting the customer know the crew is on site and work has started',
      completed:      'letting the customer know the job is done and crew has cleaned up',
      thank_you:      'a genuine personal thank you for their business after the job is complete',
    };

    const typeContext = typeDescriptions[type] || 'a job status update';
    const reviewStr  = reviewLink ? `\nInclude this review link naturally: ${reviewLink}` : '';
    const noteStr    = crewNote   ? `\nCrew note about the job: "${crewNote}"` : '';

    const prompt = `You are writing a text message from a trade contractor to their customer.

Contractor company: ${companyName}
Customer first name: ${customerName}
Job type: ${jobType}
Message purpose: ${typeContext}${reviewStr}${noteStr}

Write a single SMS text message that:
- Sounds like a real person texting, not a corporation
- Is warm, professional, and brief (2-4 sentences max)
- Starts naturally — NOT with "I hope this message finds you well" or "Dear ${customerName}"
- Uses the customer's first name once, naturally
- Does NOT use the word "thrilled", "delighted", "excited", or "pleased"
- Feels personal, like it came from the owner or crew lead personally
- Includes 1 emoji max, only if it fits naturally
${reviewLink ? '- The review link should be on its own line after the request' : ''}

Respond in this exact JSON format:
{ "message": "the text message here" }`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.85,
      max_tokens: 200,
      response_format: { type: 'json_object' },
    });

    const raw = completion.choices[0].message.content;
    let parsed;
    try {
      parsed = JSON.parse(raw);
    } catch {
      return res.status(500).json({ error: 'Failed to parse AI response' });
    }

    const message = (parsed.message || '').trim();
    if (!message) return res.status(500).json({ error: 'Empty message from AI' });

    console.log(`[OpenAI] SMS generated — type: ${type}, customer: ${customerName}, ${message.length} chars`);
    res.json({ message });

  } catch (err) {
    console.error('[OpenAI] generate-sms error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// TWILIO — SEND SMS
//
// Flutter SmsService calls POST /sms/send
// Also aliased as POST /send-sms for compatibility.
//
// Body: { to_phone, body, job_id, template_key, customer_name, type }
// Returns: { success, message: { id, sid, to, from, body, status, ... } }
// ─────────────────────────────────────────────────────────────────────────────
async function handleSendSms(req, res) {
  try {
    const {
      to_phone,
      body,
      job_id       = '',
      template_key = '',
      customer_name = '',
      type         = 'statusUpdate',
    } = req.body;

    // Support both 'to' and 'to_phone' field names
    const to = to_phone || req.body.to;

    if (!to || !body) {
      return res.status(400).json({ error: 'to_phone and body are required' });
    }

    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const authToken  = process.env.TWILIO_AUTH_TOKEN;
    const from       = process.env.TWILIO_PHONE_NUMBER;

    if (!accountSid || !authToken || !from) {
      return res.status(503).json({ error: 'Twilio not configured' });
    }

    const twilio  = require('twilio')(accountSid, authToken);
    const msg     = await twilio.messages.create({ to, from, body });

    console.log(`[Twilio] SMS sent — sid: ${msg.sid}, to: ${to}, template: ${template_key}`);

    // Return message object in the shape Flutter SmsService._parseMessage() expects
    res.json({
      success: true,
      message: {
        id:            msg.sid,
        sid:           msg.sid,
        job_id:        job_id,
        company_id:    '',
        customer_name: customer_name,
        to:            msg.to,
        from:          msg.from,
        to_phone:      msg.to,
        from_phone:    msg.from,
        body:          body,
        type:          type,
        status:        msg.status,
        template_key:  template_key,
        is_mock:       false,
        sent_at:       new Date().toISOString(),
      },
    });

  } catch (err) {
    console.error('[Twilio] send-sms error:', err.message);
    res.status(500).json({ error: err.message });
  }
}

// Register both routes — Flutter uses /sms/send
app.post('/sms/send',  handleSendSms);
app.post('/send-sms',  handleSendSms);

// ─── SMS log (stub — Twilio handles real delivery tracking) ───────────────────
app.get('/sms/log', (req, res) => {
  res.json({ messages: [] });
});

// ─────────────────────────────────────────────────────────────────────────────
// GBP — PUBLISH GOOGLE POST
//
// POST /publish-google-post
// Body: { companyId, locationId, text, imageUrl }
// ─────────────────────────────────────────────────────────────────────────────
app.post('/publish-google-post', async (req, res) => {
  try {
    const { companyId, locationId: bodyLocationId, text, imageUrl } = req.body;

    if (!text) {
      return res.status(400).json({ error: 'text is required' });
    }

    // Retrieve company's GBP access token from Firestore
    if (!db) {
      return res.status(503).json({ error: 'Firebase not configured' });
    }

    const companyDoc = await db.collection('companies').doc(companyId).get();
    const companyData = companyDoc.data() || {};
    let accessToken = companyData.gbp_access_token;

    // Auto-refresh token if available
    if (!accessToken && companyData.gbp_refresh_token) {
      accessToken = await refreshGbpToken(companyId);
    }

    if (!accessToken) {
      return res.status(401).json({ error: 'GBP not connected for this company' });
    }

    // Use locationId from body, or fall back to the one stored during OAuth
    const locationId = bodyLocationId || companyData.gbp_location_id;
    if (!locationId) {
      return res.status(400).json({ error: 'No GBP location configured for this company' });
    }

    // Post to Google Business Profile API
    // Native fetch — available in Node 18+ (no node-fetch dependency needed)
    const body = {
      languageCode: 'en-US',
      summary: text,
      topicType: 'STANDARD',
    };
    if (imageUrl) {
      body.media = [{ mediaFormat: 'PHOTO', sourceUrl: imageUrl }];
    }

    const response = await fetch(
      `https://mybusiness.googleapis.com/v4/${locationId}/localPosts`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      }
    );

    const result = await response.json();
    if (!response.ok) {
      console.error('[GBP] Post failed:', result);
      return res.status(response.status).json({ error: result.error?.message || 'GBP post failed' });
    }

    console.log(`[GBP] Post published — company: ${companyId}`);
    res.json({ success: true, post: result });

  } catch (err) {
    console.error('[GBP] publish error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// GBP OAUTH — CONNECT GOOGLE BUSINESS PROFILE
//
// Two-step OAuth2 flow so users never have to touch a Location ID.
//
// STEP 1 — Flutter calls GET /gbp/auth-url?companyId=xxx
//   • Server builds the Google OAuth consent URL with business.manage scope
//   • Returns { authUrl } — Flutter opens this in the external browser
//
// STEP 2 — Google redirects to GET /gbp/callback?code=xxx&state=companyId
//   • Server exchanges the code for access + refresh tokens
//   • Fetches the user's GBP account + first location automatically
//   • Stores gbp_access_token, gbp_refresh_token, gbp_location_id in Firestore
//   • Redirects browser to a hosted success page (or deep-link back to app)
//
// Required Railway env vars:
//   GOOGLE_CLIENT_ID      — OAuth2 Web App client ID from Google Cloud Console
//   GOOGLE_CLIENT_SECRET  — OAuth2 client secret
//   RAILWAY_PUBLIC_URL    — e.g. https://traderep-server-production.up.railway.app
//                           Used to build the redirect_uri sent to Google.
// ─────────────────────────────────────────────────────────────────────────────

const GOOGLE_CLIENT_ID     = process.env.GOOGLE_CLIENT_ID;
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET;
const RAILWAY_PUBLIC_URL   = (process.env.RAILWAY_PUBLIC_URL || 'https://traderep-server-production.up.railway.app').replace(/\/$/, '');
const GBP_REDIRECT_URI     = `${RAILWAY_PUBLIC_URL}/gbp/callback`;
const GBP_SCOPES           = [
  'https://www.googleapis.com/auth/business.manage',
  'https://www.googleapis.com/auth/userinfo.email',
].join(' ');

// ── STEP 1: Generate OAuth URL ────────────────────────────────────────────────
// GET /gbp/auth-url?companyId=xxx
// Returns: { authUrl: "https://accounts.google.com/o/oauth2/v2/auth?..." }
app.get('/gbp/auth-url', (req, res) => {
  const { companyId } = req.query;

  if (!companyId) {
    return res.status(400).json({ error: 'companyId is required' });
  }
  if (!GOOGLE_CLIENT_ID) {
    return res.status(503).json({
      error: 'Google OAuth not configured on server. Add GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET to Railway env vars.',
    });
  }

  const params = new URLSearchParams({
    client_id:     GOOGLE_CLIENT_ID,
    redirect_uri:  GBP_REDIRECT_URI,
    response_type: 'code',
    scope:         GBP_SCOPES,
    access_type:   'offline',     // needed to get a refresh_token
    prompt:        'consent',     // always show consent so we always get refresh_token
    state:         companyId,     // passed back in callback so we know which company
  });

  const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`;
  console.log(`[GBP OAuth] Auth URL generated for company: ${companyId}`);
  res.json({ authUrl });
});

// ── STEP 2: OAuth Callback ────────────────────────────────────────────────────
// GET /gbp/callback?code=xxx&state=companyId
// Exchanges code → tokens, fetches first GBP location, stores in Firestore.
app.get('/gbp/callback', async (req, res) => {
  const { code, state: companyId, error: oauthError } = req.query;

  // User denied access
  if (oauthError) {
    console.warn(`[GBP OAuth] User denied access: ${oauthError}`);
    return res.send(`<!DOCTYPE html><html><head><title>Connection Cancelled</title>
      <meta name="viewport" content="width=device-width,initial-scale=1">
      <style>body{background:#0d1b2e;color:#fff;font-family:sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}
      .card{background:#1a2840;border-radius:16px;padding:32px;text-align:center;max-width:360px}
      h2{color:#F7BE1A;margin-top:0}p{color:#a0b0c0}
      </style></head><body><div class="card"><h2>⚠️ Connection Cancelled</h2>
      <p>Google Business Profile was not connected. You can try again inside the app.</p>
      <p style="margin-top:24px;font-size:12px;color:#5a6a7a">You can close this tab.</p>
      </div></body></html>`);
  }

  if (!code || !companyId) {
    return res.status(400).send('Missing code or state');
  }
  if (!GOOGLE_CLIENT_ID || !GOOGLE_CLIENT_SECRET) {
    return res.status(503).send('Google OAuth not configured on server');
  }
  if (!db) {
    return res.status(503).send('Firebase not configured on server');
  }

  try {
    // ── Exchange code for tokens ────────────────────────────────────────────
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        code,
        client_id:     GOOGLE_CLIENT_ID,
        client_secret: GOOGLE_CLIENT_SECRET,
        redirect_uri:  GBP_REDIRECT_URI,
        grant_type:    'authorization_code',
      }).toString(),
    });

    const tokens = await tokenResponse.json();
    if (!tokenResponse.ok || !tokens.access_token) {
      console.error('[GBP OAuth] Token exchange failed:', tokens);
      throw new Error(tokens.error_description || 'Token exchange failed');
    }

    const { access_token, refresh_token } = tokens;
    console.log(`[GBP OAuth] Tokens received for company: ${companyId} | has_refresh: ${!!refresh_token}`);

    // ── Fetch user's GBP accounts ──────────────────────────────────────────
    let locationId  = null;
    let accountName = null;
    let locationDisplayName = null;

    try {
      // List accounts
      const accountsRes = await fetch(
        'https://mybusinessaccountmanagement.googleapis.com/v1/accounts',
        { headers: { Authorization: `Bearer ${access_token}` } }
      );
      const accountsData = await accountsRes.json();
      const accounts = accountsData.accounts || [];

      if (accounts.length > 0) {
        accountName = accounts[0].name; // e.g. "accounts/12345678"

        // List locations under the first account
        const locRes = await fetch(
          `https://mybusinessbusinessinformation.googleapis.com/v1/${accountName}/locations?readMask=name,title`,
          { headers: { Authorization: `Bearer ${access_token}` } }
        );
        const locData = await locRes.json();
        const locations = locData.locations || [];

        if (locations.length > 0) {
          // Use the first location — most businesses have one
          locationId = locations[0].name; // e.g. "locations/12345678"
          locationDisplayName = locations[0].title || '';
          // GBP post API needs "accounts/xxx/locations/yyy" format
          if (locationId && accountName && !locationId.startsWith('accounts/')) {
            locationId = `${accountName}/${locationId}`;
          }
          console.log(`[GBP OAuth] Found location: ${locationId} ("${locationDisplayName}")`);
        } else {
          console.warn(`[GBP OAuth] No locations found under account: ${accountName}`);
        }
      } else {
        console.warn('[GBP OAuth] No GBP accounts found for this Google user');
      }
    } catch (locationErr) {
      // Non-fatal — tokens are still good, we just couldn't auto-detect location
      console.warn('[GBP OAuth] Location fetch failed (non-fatal):', locationErr.message);
    }

    // ── Save tokens + locationId to Firestore ─────────────────────────────
    const updateData = {
      gbp_access_token:   access_token,
      gbp_connected:      true,
      gbp_connected_at:   admin.firestore.FieldValue.serverTimestamp(),
    };
    if (refresh_token) updateData.gbp_refresh_token = refresh_token;
    if (locationId)    updateData.gbp_location_id   = locationId;
    if (locationDisplayName) updateData.gbp_location_name = locationDisplayName;

    await db.collection('companies').doc(companyId).set(updateData, { merge: true });
    console.log(`[GBP OAuth] ✅ Company ${companyId} connected — location: ${locationId || 'not found'}`);

    // ── Success HTML page ──────────────────────────────────────────────────
    const locationLine = locationId
      ? `<p style="color:#a0b0c0;font-size:13px">Connected to: <strong style="color:#F7BE1A">${locationDisplayName || locationId}</strong></p>`
      : `<p style="color:#a0b0c0;font-size:13px">No Business Profile location found on this account.<br>You can set it manually inside the app.</p>`;

    return res.send(`<!DOCTYPE html><html><head><title>Google Business Connected</title>
      <meta name="viewport" content="width=device-width,initial-scale=1">
      <style>
        body{background:#0d1b2e;color:#fff;font-family:sans-serif;display:flex;align-items:center;
             justify-content:center;min-height:100vh;margin:0;padding:20px;box-sizing:border-box}
        .card{background:#1a2840;border:1px solid #2a3850;border-radius:16px;padding:36px 28px;
              text-align:center;max-width:380px;width:100%}
        .check{width:64px;height:64px;background:#1a3a20;border-radius:50%;display:flex;
               align-items:center;justify-content:center;margin:0 auto 20px;font-size:30px}
        h2{color:#F7BE1A;margin:0 0 8px;font-size:22px}
        .note{margin-top:28px;padding:12px;background:#0d1b2e;border-radius:10px;
              font-size:12px;color:#5a6a7a}
      </style></head>
      <body><div class="card">
        <div class="check">✅</div>
        <h2>Google Business Connected!</h2>
        ${locationLine}
        <div class="note">You can close this tab and return to the TradeRep app.</div>
      </div></body></html>`);

  } catch (err) {
    console.error('[GBP OAuth] Callback error:', err.message);
    return res.send(`<!DOCTYPE html><html><head><title>Connection Failed</title>
      <meta name="viewport" content="width=device-width,initial-scale=1">
      <style>body{background:#0d1b2e;color:#fff;font-family:sans-serif;display:flex;align-items:center;
             justify-content:center;min-height:100vh;margin:0}
      .card{background:#1a2840;border-radius:16px;padding:32px;text-align:center;max-width:360px}
      h2{color:#e05555;margin-top:0}p{color:#a0b0c0}code{color:#F7BE1A;font-size:11px}
      </style></head><body><div class="card"><h2>❌ Connection Failed</h2>
      <p>${err.message}</p>
      <p>Please return to the TradeRep app and try again.</p>
      </div></body></html>`);
  }
});

// ── Token refresh helper (internal — called by /publish-google-post) ──────────
// Automatically refreshes an expired access_token using the stored refresh_token.
async function refreshGbpToken(companyId) {
  if (!GOOGLE_CLIENT_ID || !GOOGLE_CLIENT_SECRET) return null;
  if (!db) return null;

  try {
    const doc = await db.collection('companies').doc(companyId).get();
    const refreshToken = doc.data()?.gbp_refresh_token;
    if (!refreshToken) return null;

    const res = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id:     GOOGLE_CLIENT_ID,
        client_secret: GOOGLE_CLIENT_SECRET,
        refresh_token: refreshToken,
        grant_type:    'refresh_token',
      }).toString(),
    });

    const data = await res.json();
    if (!res.ok || !data.access_token) {
      console.warn('[GBP OAuth] Token refresh failed:', data.error);
      return null;
    }

    // Store updated access_token
    await db.collection('companies').doc(companyId).update({
      gbp_access_token: data.access_token,
    });
    console.log(`[GBP OAuth] Token refreshed for company: ${companyId}`);
    return data.access_token;

  } catch (e) {
    console.error('[GBP OAuth] refreshGbpToken error:', e.message);
    return null;
  }
}

// ── GBP OAuth status check ────────────────────────────────────────────────────
// GET /gbp/status?companyId=xxx
// Returns current connection state so Flutter can poll after redirect.
app.get('/gbp/status', async (req, res) => {
  const { companyId } = req.query;
  if (!companyId || !db) return res.json({ connected: false });

  try {
    const doc = await db.collection('companies').doc(companyId).get();
    const data = doc.data() || {};
    res.json({
      connected:     !!data.gbp_connected,
      location_id:   data.gbp_location_id   || null,
      location_name: data.gbp_location_name || null,
      oauth_enabled: !!(GOOGLE_CLIENT_ID && GOOGLE_CLIENT_SECRET),
    });
  } catch (e) {
    res.json({ connected: false, error: e.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// START SERVER
// ─────────────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`[Server] TradeRep Pro backend running on port ${PORT}`);
  console.log(`[Server] Stripe:  ${process.env.STRIPE_SECRET_KEY ? '✅' : '❌ not configured'}`);
  console.log(`[Server] Twilio:  ${process.env.TWILIO_ACCOUNT_SID ? '✅' : '⚠️  not configured'}`);
  console.log(`[Server] Firebase:${db ? '✅' : '⚠️  not configured'}`);
  console.log(`[Server] OpenAI:  ${openai ? '✅' : '⚠️  not configured — add OPENAI_API_KEY'}`);
});
