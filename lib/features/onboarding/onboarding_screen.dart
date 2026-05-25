import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/widgets/tr_widgets.dart';
import '../../shared/models/models.dart';
import '../auth/sign_in_screen.dart';
import '../auth/sign_up_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6;

  // Form controllers
  final _companyNameCtrl = TextEditingController(text: '');
  final _phoneCtrl = TextEditingController(text: '');
  final _websiteCtrl = TextEditingController(text: '');
  final _serviceAreaCtrl = TextEditingController(text: '');
  String? _selectedCategory;
  int _teamSize = 1;

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.read<AppState>().completeOnboarding();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _WelcomePage(onNext: _nextPage),
                  _CompanyInfoPage(
                    nameCtrl: _companyNameCtrl,
                    phoneCtrl: _phoneCtrl,
                    websiteCtrl: _websiteCtrl,
                    serviceAreaCtrl: _serviceAreaCtrl,
                    onNext: _nextPage,
                  ),
                  _TradeCategoryPage(
                    selected: _selectedCategory,
                    onSelect: (cat) => setState(() => _selectedCategory = cat),
                    onNext: _nextPage,
                  ),
                  _TeamSizePage(
                    teamSize: _teamSize,
                    onChanged: (v) => setState(() => _teamSize = v),
                    onNext: _nextPage,
                  ),
                  _GoogleConnectPage(onNext: _nextPage),
                  _ReadyPage(onNext: _nextPage),
                ],
              ),
            ),
            if (_currentPage > 0 && _currentPage < _totalPages - 1)
              _buildNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          if (_currentPage > 0)
            GestureDetector(
              onTap: _prevPage,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: TRColors.cardMid,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TRColors.divider),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: TRColors.white, size: 20),
              ),
            )
          else
            const SizedBox(width: 40),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentPage ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _currentPage ? TRColors.gold : TRColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
          if (_currentPage > 0 && _currentPage < _totalPages - 1)
            TextButton(
              onPressed: _nextPage,
              child: const Text('Skip', style: TextStyle(color: TRColors.grayMid, fontSize: 14)),
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GoldButton(label: 'Continue', icon: Icons.arrow_forward_rounded, onTap: _nextPage),
    );
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _serviceAreaCtrl.dispose();
    super.dispose();
  }
}

// ─── Page 1: Welcome ──────────────────────────────────────────────────────────
class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          const TRLogo(size: 100, showTagline: true),
          const Spacer(flex: 2),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TRColors.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TRColors.divider),
            ),
            child: Column(
              children: [
                _FeaturePill(icon: Icons.camera_alt_rounded, text: 'Document every job with AI-guided photos'),
                const SizedBox(height: 12),
                _FeaturePill(icon: Icons.star_rounded, text: 'Auto-generate Google review requests'),
                const SizedBox(height: 12),
                _FeaturePill(icon: Icons.business_rounded, text: 'Publish content to your Google Business Profile'),
                const SizedBox(height: 12),
                _FeaturePill(icon: Icons.analytics_rounded, text: 'Track reputation growth over time'),
              ],
            ),
          ),
          const Spacer(flex: 2),
          GoldButton(
            label: 'Get Started — It\'s Free',
            icon: Icons.rocket_launch_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SignUpScreen()),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SignInScreen()),
            ),
            child: const Text(
              'Already have an account? Sign in',
              style: TextStyle(color: TRColors.grayLight, fontSize: 14),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeaturePill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TRColors.goldDim,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: TRColors.gold, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: TRColors.white, fontSize: 14))),
      ],
    );
  }
}

// ─── Page 2: Company Info ─────────────────────────────────────────────────────
class _CompanyInfoPage extends StatelessWidget {
  final TextEditingController nameCtrl, phoneCtrl, websiteCtrl, serviceAreaCtrl;
  final VoidCallback onNext;

  const _CompanyInfoPage({
    required this.nameCtrl, required this.phoneCtrl,
    required this.websiteCtrl, required this.serviceAreaCtrl,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Set Up Your Company', style: TextStyle(
            color: TRColors.white, fontSize: 26, fontWeight: FontWeight.w800,
          )),
          const SizedBox(height: 6),
          const Text('This is your reputation home base.', style: TextStyle(
            color: TRColors.grayLight, fontSize: 15,
          )),
          const SizedBox(height: 32),

          // Logo Upload
          Center(
            child: Column(
              children: [
                GestureDetector(
                  child: Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: TRColors.cardMid,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TRColors.gold, width: 1.5, style: BorderStyle.solid),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, color: TRColors.gold, size: 30),
                        SizedBox(height: 4),
                        Text('Logo', style: TextStyle(color: TRColors.gold, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Tap to upload company logo', style: TextStyle(color: TRColors.grayMid, fontSize: 12)),
              ],
            ),
          ),

          const SizedBox(height: 28),
          _TRField(controller: nameCtrl, label: 'Company Name', icon: Icons.business_rounded, hint: 'e.g. Apex Roofing & Construction'),
          const SizedBox(height: 14),
          _TRField(controller: phoneCtrl, label: 'Phone Number', icon: Icons.phone_rounded, hint: '(555) 000-0000', keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          _TRField(controller: websiteCtrl, label: 'Website (optional)', icon: Icons.language_rounded, hint: 'yourcompany.com'),
          const SizedBox(height: 14),
          _TRField(controller: serviceAreaCtrl, label: 'Service Area', icon: Icons.location_on_rounded, hint: 'e.g. Denver, CO (50-mile radius)'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _TRField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;

  const _TRField({
    required this.controller, required this.label,
    required this.icon, required this.hint, this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          color: TRColors.grayLight, fontSize: 13, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: TRColors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
          ),
        ),
      ],
    );
  }
}

// ─── Page 3: Trade Category ───────────────────────────────────────────────────
class _TradeCategoryPage extends StatelessWidget {
  final String? selected;
  final Function(String) onSelect;
  final VoidCallback onNext;

  const _TradeCategoryPage({required this.selected, required this.onSelect, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('What\'s Your Trade?', style: TextStyle(
            color: TRColors.white, fontSize: 26, fontWeight: FontWeight.w800,
          )),
          const SizedBox(height: 6),
          const Text('We\'ll customize TradeRep for your industry.', style: TextStyle(
            color: TRColors.grayLight, fontSize: 15,
          )),
          const SizedBox(height: 28),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.4,
            ),
            itemCount: TradeCategory.values.length,
            itemBuilder: (_, i) {
              final cat = TradeCategory.values[i];
              final isSelected = selected == cat.displayName;
              return GestureDetector(
                onTap: () => onSelect(cat.displayName),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? TRColors.goldDim : TRColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? TRColors.gold : TRColors.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(cat.displayName, style: TextStyle(
                        color: isSelected ? TRColors.gold : TRColors.white,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Page 4: Team Size ────────────────────────────────────────────────────────
class _TeamSizePage extends StatelessWidget {
  final int teamSize;
  final Function(int) onChanged;
  final VoidCallback onNext;

  const _TeamSizePage({required this.teamSize, required this.onChanged, required this.onNext});

  static const List<Map<String, dynamic>> _sizes = [
    {'label': 'Solo', 'range': '1', 'icon': Icons.person_rounded},
    {'label': 'Small Crew', 'range': '2–5', 'icon': Icons.group_rounded},
    {'label': 'Mid-Size', 'range': '6–15', 'icon': Icons.groups_rounded},
    {'label': 'Large Company', 'range': '16+', 'icon': Icons.corporate_fare_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('How Big Is Your Team?', style: TextStyle(
            color: TRColors.white, fontSize: 26, fontWeight: FontWeight.w800,
          )),
          const SizedBox(height: 6),
          const Text('We\'ll set up the right workflow for your size.', style: TextStyle(
            color: TRColors.grayLight, fontSize: 15,
          )),
          const SizedBox(height: 32),
          ...List.generate(_sizes.length, (i) {
            final size = _sizes[i];
            final isSelected = teamSize == i + 1;
            return GestureDetector(
              onTap: () => onChanged(i + 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected ? TRColors.goldDim : TRColors.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? TRColors.gold : TRColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? TRColors.gold.withValues(alpha: 0.25) : TRColors.cardMid,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(size['icon'] as IconData,
                        color: isSelected ? TRColors.gold : TRColors.grayLight, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(size['label'] as String, style: TextStyle(
                          color: isSelected ? TRColors.gold : TRColors.white,
                          fontSize: 16, fontWeight: FontWeight.w700,
                        )),
                        Text('${size['range']} people', style: const TextStyle(
                          color: TRColors.grayLight, fontSize: 13,
                        )),
                      ],
                    )),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: TRColors.gold, size: 22),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Page 5: Google Connect ───────────────────────────────────────────────────
class _GoogleConnectPage extends StatefulWidget {
  final VoidCallback onNext;
  const _GoogleConnectPage({required this.onNext});

  @override
  State<_GoogleConnectPage> createState() => _GoogleConnectPageState();
}

class _GoogleConnectPageState extends State<_GoogleConnectPage> {
  bool _connecting = false;
  bool _connected = false;

  void _connectGoogle() async {
    setState(() => _connecting = true);
    await Future.delayed(const Duration(seconds: 2));
    context.read<AppState>().connectGoogle();
    setState(() { _connecting = false; _connected = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: TRColors.cardMid,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _connected ? TRColors.success : TRColors.divider, width: _connected ? 2 : 1),
            ),
            child: _connected
              ? const Icon(Icons.check_circle_rounded, color: TRColors.success, size: 42)
              : const Icon(Icons.business_rounded, color: TRColors.grayLight, size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            _connected ? 'Google Business Connected!' : 'Connect Google Business Profile',
            style: const TextStyle(color: TRColors.white, fontSize: 22, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            _connected
              ? 'TradeRep is now connected to your Google Business Profile. You can post projects and photos directly.'
              : 'Connect your Google Business Profile to post project photos, updates, and manage your review link.',
            style: const TextStyle(color: TRColors.grayLight, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (!_connected) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TRColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TRColors.divider),
              ),
              child: Column(
                children: [
                  _PermissionRow(icon: Icons.photo_camera_rounded, text: 'Upload project photos to your listing'),
                  const Divider(color: TRColors.divider, height: 20),
                  _PermissionRow(icon: Icons.post_add_rounded, text: 'Publish approved Google posts'),
                  const Divider(color: TRColors.divider, height: 20),
                  _PermissionRow(icon: Icons.star_rounded, text: 'Access review links and responses'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _connecting
              ? const SizedBox(height: 54, child: Center(child: CircularProgressIndicator(color: TRColors.gold)))
              : GoldButton(
                  label: 'Sign in with Google',
                  icon: Icons.login_rounded,
                  onTap: _connectGoogle,
                ),
            const SizedBox(height: 12),
            GoldButton(
              label: 'Skip for now',
              outlined: true,
              onTap: widget.onNext,
            ),
          ] else
            GoldButton(label: 'Continue', icon: Icons.arrow_forward_rounded, onTap: widget.onNext),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PermissionRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: TRColors.gold, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: TRColors.white, fontSize: 14))),
        const Icon(Icons.check_circle_outline_rounded, color: TRColors.success, size: 16),
      ],
    );
  }
}

// ─── Page 6: Ready ────────────────────────────────────────────────────────────
class _ReadyPage extends StatelessWidget {
  final VoidCallback onNext;
  const _ReadyPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: const RadialGradient(colors: [Color(0x30F7BE1A), TRColors.navyDeep]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.rocket_launch_rounded, color: TRColors.gold, size: 52),
          ),
          const SizedBox(height: 24),
          const Text('You\'re All Set!', style: TextStyle(
            color: TRColors.white, fontSize: 30, fontWeight: FontWeight.w800,
          )),
          const SizedBox(height: 12),
          const Text(
            'TradeRep is ready to turn your completed jobs into online credibility — automatically.',
            style: TextStyle(color: TRColors.grayLight, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _ReadyItem(icon: Icons.folder_open_rounded, title: 'Create your first job', subtitle: 'Start documenting immediately'),
          const SizedBox(height: 12),
          _ReadyItem(icon: Icons.camera_alt_rounded, title: 'Assign crew to capture photos', subtitle: 'AI-guided shot framing'),
          const SizedBox(height: 12),
          _ReadyItem(icon: Icons.auto_awesome_rounded, title: 'AI generates your content', subtitle: 'Review and approve posts'),
          const Spacer(),
          GoldButton(
            label: 'Enter TradeRep',
            icon: Icons.arrow_forward_rounded,
            onTap: onNext,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ReadyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ReadyItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TRColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TRColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TRColors.goldDim,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: TRColors.gold, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              Text(subtitle, style: const TextStyle(color: TRColors.grayMid, fontSize: 12)),
            ],
          )),
          const Icon(Icons.arrow_forward_ios_rounded, color: TRColors.grayMid, size: 14),
        ],
      ),
    );
  }
}
