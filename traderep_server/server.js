// TradeRep Pro â€” Railway Backend Server
// Handles: Stripe subscriptions, Twilio SMS, GBP posting
// All sensitive keys live in Railway environment variables â€” never in the app.

'use strict';
require('dotenv').config();

const express    = require('express');
const cors       = require('cors');
const stripe     = require('stripe')(process.env.STRIPE_SECRET_KEY);
const admin      = require('firebase-admin');
const { OpenAI } = require('openai');

// â”€â”€ OpenAI client â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const openai = process.env.OPENAI_API_KEY
  ? new OpenAI({ apiKey: process.env.OPENAI_API_KEY })
  : null;
if (openai) {
  console.log('[OpenAI] Client initialized âœ…');
} else {
  console.warn('[OpenAI] OPENAI_API_KEY not set â€” caption generation disabled');
}

// â”€â”€ Firebase Admin init â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
let db = null;
try {
  const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT || '{}');
  if (serviceAccount.project_id) {
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    db = admin.firestore();
    console.log('[Firebase] Initialized âœ… â€” project:', serviceAccount.project_id);
  } else {
    console.warn('[Firebase] FIREBASE_SERVICE_ACCOUNT not set â€” Firestore sync disabled');
  }
} catch (e) {
  console.error('[Firebase] Init error:', e.message);
}

// â”€â”€ Express setup â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const app = express();

// IMPORTANT: raw body required for Stripe webhook signature verification.
// Must be registered BEFORE express.json() middleware.
app.use('/stripe-webhook', express.raw({ type: 'application/json' }));
app.use(cors());
app.use(express.json());

// â”€â”€ Price ID map â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const PRICE_IDS = {
  starter: process.env.STRIPE_PRICE_STARTER || 'price_1TcTIkCnWFtpnJDSLagxlQCu',
  growth:  process.env.STRIPE_PRICE_GROWTH  || 'price_1TcTJXCnWFtpnJDSXlZpYOs9',
  pro:     process.env.STRIPE_PRICE_PRO     || 'price_1TcTKICnWFtpnJDSmXw4CrWZ',
};

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// HEALTH CHECK
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
  });
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// OPENAI â€” GENERATE CAPTION
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
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
      professional: 'professional and trustworthy â€” highlight quality and reliability',
      friendly:     'warm and conversational â€” like a neighbor recommending a trusted contractor',
      bold:         'confident and punchy â€” short sentences, strong verbs, make them want to call',
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
- 3â€“5 sentences max â€” no fluff
- Follow the opening style instruction above
- Mention the specific job type naturally
- Include a call to action at the end (vary it â€” not always "Call us for a free estimate")
- Do NOT use: "thrilled", "delighted", "excited", "proud", "we are pleased"
- Do NOT start with "We just completed" or "We are happy to"
- Sound like the contractor wrote it themselves â€” real, not corporate
- Location mention is optional â€” only include if it fits naturally
- Include 1â€“2 emojis placed naturally (not at the start)

Also generate 6 relevant hashtags (no spaces, each starting with #).
Mix trade-specific tags with local/general ones.

Respond in this exact JSON format:
{
  "caption": "the post text here",
  "hashtags": ["#Tag1", "#Tag2", "#Tag3", "#Tag4", "#Tag5", "#Tag6"]
}`;

    console.log(`[OpenAI] Generating caption â€” trade: ${trade}, job: ${jobType}, tone: ${tone}`);

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',          // fast and cheap â€” ~$0.0002 per caption
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
      console.error('[OpenAI] JSON parse error â€” raw:', raw);
      return res.status(500).json({ error: 'Failed to parse AI response' });
    }

    const caption   = (parsed.caption   || '').trim();
    const hashtags  = Array.isArray(parsed.hashtags) ? parsed.hashtags : [];

    if (!caption) {
      return res.status(500).json({ error: 'Empty caption from AI' });
    }

    console.log(`[OpenAI] Caption generated â€” ${caption.length} chars, ${hashtags.length} hashtags`);
    res.json({ caption, hashtags });

  } catch (err) {
    console.error('[OpenAI] generate-caption error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// STRIPE â€” CREATE SUBSCRIPTION
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
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

    console.log(`[Stripe] create-subscription â€” company: ${companyId}, plan: ${priceKey}`);

    // â”€â”€ 1. Find or create Stripe Customer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

    // â”€â”€ 2. Create Subscription with 14-day trial â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // payment_behavior: 'default_incomplete' means the subscription is created
    // but stays incomplete until the customer confirms their payment method.
    // trial_period_days: 14 â€” no charge for 14 days.
    // payment_settings.save_default_payment_method: 'on_subscription' â€” card
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

    console.log(`[Stripe] Subscription created: ${subscription.id} â€” status: ${subscription.status}`);

    // â”€â”€ 3. Extract client_secret for Flutter payment sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    const paymentIntent = subscription.latest_invoice?.payment_intent;
    const clientSecret  = paymentIntent?.client_secret || null;

    // â”€â”€ 4. Persist subscription to Firestore â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
      console.log(`[Firestore] Subscription written â€” trial ends: ${trialEnd.toISOString()}`);
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// STRIPE â€” WEBHOOK
//
// Stripe calls this endpoint when subscription events occur.
// Signature verification ensures requests are genuinely from Stripe.
// Updates Firestore so the app always reflects the true subscription state.
//
// POST /stripe-webhook
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
app.post('/stripe-webhook', async (req, res) => {
  const sig     = req.headers['stripe-signature'];
  const secret  = process.env.STRIPE_WEBHOOK_SECRET;

  if (!secret) {
    console.warn('[Webhook] STRIPE_WEBHOOK_SECRET not set â€” skipping verification');
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

      // â”€â”€ Trial will end soon (3 days warning) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      case 'customer.subscription.trial_will_end': {
        const sub       = event.data.object;
        const companyId = sub.metadata?.companyId;
        if (companyId && db) {
          await db.collection('companies').doc(companyId).update({
            'subscription.status':    'trial_ending',
            'subscription.updated_at': admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`[Webhook] Trial ending soon â€” company: ${companyId}`);
        }
        break;
      }

      // â”€â”€ Subscription updated (trial â†’ active, plan change, etc.) â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
          console.log(`[Webhook] Subscription updated â€” company: ${companyId}, status: ${sub.status}`);
        }
        break;
      }

      // â”€â”€ Payment succeeded (trial ended, card charged successfully) â”€â”€â”€â”€â”€â”€â”€â”€
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
          console.log(`[Webhook] Payment succeeded â€” company: ${companyId}`);
        }
        break;
      }

      // â”€â”€ Payment failed (card declined after trial) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
          console.log(`[Webhook] Payment failed â€” company: ${companyId}`);
        }
        break;
      }

      // â”€â”€ Subscription cancelled â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      case 'customer.subscription.deleted': {
        const sub       = event.data.object;
        const companyId = sub.metadata?.companyId;
        if (companyId && db) {
          await db.collection('companies').doc(companyId).update({
            'subscription.status':     'canceled',
            'subscription.updated_at': admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`[Webhook] Subscription cancelled â€” company: ${companyId}`);
        }
        break;
      }

      default:
        console.log(`[Webhook] Unhandled event type: ${event.type}`);
    }
  } catch (err) {
    console.error('[Webhook] Handler error:', err.message);
    // Still return 200 so Stripe doesn't retry â€” log the error for investigation
  }

  res.json({ received: true });
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// OPENAI â€” GENERATE SMS
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
//   reviewLink,    // optional â€” Google review URL
//   crewNote,      // optional â€” any context the crew added
// }
// Returns: { message }
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
- Starts naturally â€” NOT with "I hope this message finds you well" or "Dear ${customerName}"
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

    console.log(`[OpenAI] SMS generated â€” type: ${type}, customer: ${customerName}, ${message.length} chars`);
    res.json({ message });

  } catch (err) {
    console.error('[OpenAI] generate-sms error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// TWILIO â€” SEND SMS
//
// Flutter SmsService calls POST /sms/send
// Also aliased as POST /send-sms for compatibility.
//
// Body: { to_phone, body, job_id, template_key, customer_name, type }
// Returns: { success, message: { id, sid, to, from, body, status, ... } }
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

    console.log(`[Twilio] SMS sent â€” sid: ${msg.sid}, to: ${to}, template: ${template_key}`);

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

// Register both routes â€” Flutter uses /sms/send
app.post('/sms/send',  handleSendSms);
app.post('/send-sms',  handleSendSms);

// â”€â”€â”€ SMS log (stub â€” Twilio handles real delivery tracking) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
app.get('/sms/log', (req, res) => {
  res.json({ messages: [] });
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// GBP â€” PUBLISH GOOGLE POST
//
// POST /publish-google-post
// Body: { companyId, locationId, text, imageUrl }
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
app.post('/publish-google-post', async (req, res) => {
  try {
    const { companyId, locationId, text, imageUrl } = req.body;

    if (!locationId || !text) {
      return res.status(400).json({ error: 'locationId and text are required' });
    }

    // Retrieve company's GBP access token from Firestore
    if (!db) {
      return res.status(503).json({ error: 'Firebase not configured' });
    }

    const companyDoc = await db.collection('companies').doc(companyId).get();
    const accessToken = companyDoc.data()?.gbp_access_token;

    if (!accessToken) {
      return res.status(401).json({ error: 'GBP not connected for this company' });
    }

    // Post to Google Business Profile API
    const fetch = (await import('node-fetch')).default;
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

    console.log(`[GBP] Post published â€” company: ${companyId}`);
    res.json({ success: true, post: result });

  } catch (err) {
    console.error('[GBP] publish error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// START SERVER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`[Server] TradeRep Pro backend running on port ${PORT}`);
  console.log(`[Server] Stripe:  ${process.env.STRIPE_SECRET_KEY ? 'âœ…' : 'âŒ not configured'}`);
  console.log(`[Server] Twilio:  ${process.env.TWILIO_ACCOUNT_SID ? 'âœ…' : 'âš ï¸  not configured'}`);
  console.log(`[Server] Firebase:${db ? 'âœ…' : 'âš ï¸  not configured'}`);
  console.log(`[Server] OpenAI:  ${openai ? 'âœ…' : 'âš ï¸  not configured â€” add OPENAI_API_KEY'}`);
});
