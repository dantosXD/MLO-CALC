import 'package:flutter/material.dart';
import 'package:loan_ranger/src/core/theme/theme_provider.dart';
import 'package:loan_ranger/src/features/calculator/application/providers/layout_preference_provider.dart';
import 'package:loan_ranger/src/features/nlp/application/providers/nlp_settings_provider.dart';
import 'package:loan_ranger/src/features/settings/domain/providers/mlo_profile_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: const [
          _MloProfileSection(),
          Divider(height: 32),
          _DisclaimerSection(),
          Divider(height: 32),
          _CalculatorDefaultsSection(),
          Divider(height: 32),
          _AppearanceSection(),
          Divider(height: 32),
          _CalculatorLayoutSection(),
          Divider(height: 32),
          _AiVoiceSection(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

// ─── MLO Profile ───────────────────────────────────────────────────────────

class _MloProfileSection extends StatefulWidget {
  const _MloProfileSection();

  @override
  State<_MloProfileSection> createState() => _MloProfileSectionState();
}

class _MloProfileSectionState extends State<_MloProfileSection> {
  final _nameCtrl = TextEditingController();
  final _nmlsCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _dirty = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = context.read<MloProfileProvider>();
    _nameCtrl.text = p.mloName;
    _nmlsCtrl.text = p.mloNmls;
    _companyCtrl.text = p.mloCompany;
    _phoneCtrl.text = p.mloPhone;
    _emailCtrl.text = p.mloEmail;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nmlsCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    await context.read<MloProfileProvider>().saveProfile(
      name: _nameCtrl.text.trim(),
      nmls: _nmlsCtrl.text.trim(),
      company: _companyCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          'MLO Profile',
          subtitle:
              'Your info appears on shared quotes. NMLS# is required by federal law.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              _SettingsTextField(
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'Jane Smith',
                icon: Icons.person_outline,
                onChanged: (_) => _markDirty(),
              ),
              const SizedBox(height: 10),
              _SettingsTextField(
                controller: _nmlsCtrl,
                label: 'NMLS #',
                hint: '1234567',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                onChanged: (_) => _markDirty(),
              ),
              const SizedBox(height: 10),
              _SettingsTextField(
                controller: _companyCtrl,
                label: 'Company / Brokerage',
                hint: 'Acme Mortgage Co.',
                icon: Icons.business_outlined,
                onChanged: (_) => _markDirty(),
              ),
              const SizedBox(height: 10),
              _SettingsTextField(
                controller: _phoneCtrl,
                label: 'Phone',
                hint: '(555) 555-5555',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                onChanged: (_) => _markDirty(),
              ),
              const SizedBox(height: 10),
              _SettingsTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'jane@acmemortgage.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => _markDirty(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _dirty ? _save : null,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Disclaimer ────────────────────────────────────────────────────────────

class _DisclaimerSection extends StatefulWidget {
  const _DisclaimerSection();

  @override
  State<_DisclaimerSection> createState() => _DisclaimerSectionState();
}

class _DisclaimerSectionState extends State<_DisclaimerSection> {
  final _ctrl = TextEditingController();
  bool _dirty = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ctrl.text = context.read<MloProfileProvider>().disclaimerText;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await context.read<MloProfileProvider>().saveDisclaimer(_ctrl.text.trim());
    if (!mounted) return;
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disclaimer saved'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          'Disclaimer Text',
          subtitle:
              'Appended to every shared quote. Customize for your state/company requirements.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              TextField(
                controller: _ctrl,
                maxLines: 5,
                maxLength: 600,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  labelText: 'Disclaimer',
                ),
                onChanged: (_) {
                  if (!_dirty) setState(() => _dirty = true);
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _dirty ? _save : null,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Disclaimer'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Calculator Defaults ───────────────────────────────────────────────────

class _CalculatorDefaultsSection extends StatefulWidget {
  const _CalculatorDefaultsSection();

  @override
  State<_CalculatorDefaultsSection> createState() =>
      _CalculatorDefaultsSectionState();
}

class _CalculatorDefaultsSectionState
    extends State<_CalculatorDefaultsSection> {
  final _rateCtrl = TextEditingController();
  final _termCtrl = TextEditingController();
  final _downCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _insCtrl = TextEditingController();
  bool _dirty = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = context.read<MloProfileProvider>();
    _rateCtrl.text = p.defaultInterestRate?.toString() ?? '';
    _termCtrl.text = p.defaultTermYears?.toString() ?? '';
    _downCtrl.text = p.defaultDownPaymentPct?.toString() ?? '';
    _taxCtrl.text = p.defaultPropertyTaxRate?.toString() ?? '';
    _insCtrl.text = p.defaultInsuranceRate?.toString() ?? '';
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    _termCtrl.dispose();
    _downCtrl.dispose();
    _taxCtrl.dispose();
    _insCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await context.read<MloProfileProvider>().saveCalculatorDefaults(
      interestRate: double.tryParse(_rateCtrl.text),
      termYears: double.tryParse(_termCtrl.text),
      downPaymentPct: double.tryParse(_downCtrl.text),
      propertyTaxRate: double.tryParse(_taxCtrl.text),
      insuranceRate: double.tryParse(_insCtrl.text),
    );
    if (!mounted) return;
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Defaults saved — applied to new sessions'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          'Calculator Defaults',
          subtitle:
              'Pre-fill these values when the calculator has no prior session.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SettingsTextField(
                      controller: _rateCtrl,
                      label: 'Interest Rate %',
                      hint: '6.875',
                      icon: Icons.percent,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _markDirty(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SettingsTextField(
                      controller: _termCtrl,
                      label: 'Term (years)',
                      hint: '30',
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _markDirty(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SettingsTextField(
                      controller: _downCtrl,
                      label: 'Down Payment %',
                      hint: '20',
                      icon: Icons.arrow_downward,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _markDirty(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SettingsTextField(
                      controller: _taxCtrl,
                      label: 'Prop. Tax Rate %',
                      hint: '1.2',
                      icon: Icons.account_balance_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _markDirty(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SettingsTextField(
                      controller: _insCtrl,
                      label: 'Insurance Rate %',
                      hint: '0.5',
                      icon: Icons.shield_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _markDirty(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _dirty ? _save : null,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Defaults'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }
}

// ─── Appearance ────────────────────────────────────────────────────────────

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  static const _accentOptions = [
    (label: 'Teal', value: 0xFF0891B2),
    (label: 'Navy', value: 0xFF1A365D),
    (label: 'Indigo', value: 0xFF4F46E5),
    (label: 'Violet', value: 0xFF7C3AED),
    (label: 'Emerald', value: 0xFF059669),
    (label: 'Amber', value: 0xFFD97706),
    (label: 'Rose', value: 0xFFE11D48),
    (label: 'Slate', value: 0xFF475569),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final mlo = context.watch<MloProfileProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Appearance'),
        SwitchListTile(
          title: const Text('Dark Mode'),
          secondary: Icon(
            theme.themeMode == ThemeMode.dark
                ? Icons.dark_mode
                : Icons.light_mode_outlined,
          ),
          value: theme.themeMode == ThemeMode.dark,
          onChanged: (_) => theme.toggleTheme(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Accent Color',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _accentOptions.map((opt) {
                  final selected = mlo.accentColorValue == opt.value;
                  return Tooltip(
                    message: opt.label,
                    child: InkWell(
                      onTap: () => context
                          .read<MloProfileProvider>()
                          .setAccentColor(opt.value),
                      borderRadius: BorderRadius.circular(24),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(opt.value),
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  width: 3,
                                )
                              : null,
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: Color(
                                      opt.value,
                                    ).withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Calculator Layout ─────────────────────────────────────────────────────

class _CalculatorLayoutSection extends StatelessWidget {
  const _CalculatorLayoutSection();

  @override
  Widget build(BuildContext context) {
    final pref = context.watch<LayoutPreferenceProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          'Calculator Layout',
          subtitle:
              'Classic is the original button-based layout. '
              'Modern uses a form-based input.',
        ),
        RadioListTile<CalculatorLayout>(
          title: const Text('Classic'),
          subtitle: const Text('Familiar calculator button pad'),
          value: CalculatorLayout.classic,
          groupValue: pref.layout,
          onChanged: (v) => pref.setLayout(v!),
        ),
        RadioListTile<CalculatorLayout>(
          title: const Text('Modern'),
          subtitle: const Text('Form-based with labeled fields'),
          value: CalculatorLayout.modern,
          groupValue: pref.layout,
          onChanged: (v) => pref.setLayout(v!),
        ),
      ],
    );
  }
}

// ─── AI / Voice ────────────────────────────────────────────────────────────

class _AiVoiceSection extends StatelessWidget {
  const _AiVoiceSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          'AI / Voice Input',
          subtitle:
              'Requires a Google Gemini API key for natural-language queries.',
        ),
        ListTile(
          leading: const Icon(Icons.key_outlined),
          title: const Text('Gemini API Key'),
          subtitle: context.watch<NlpSettingsProvider>().apiKey != null
              ? const Text('Configured', style: TextStyle(color: Colors.green))
              : const Text('Not set'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showApiKeySheet(context),
        ),
      ],
    );
  }

  void _showApiKeySheet(BuildContext context) {
    final settings = context.read<NlpSettingsProvider>();
    final controller = TextEditingController(text: settings.apiKey ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final navigator = Navigator.of(ctx);
        final messenger = ScaffoldMessenger.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gemini API Key',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Enter your Gemini API key',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await settings.setApiKey(controller.text);
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('API key saved')),
                      );
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () async {
                      controller.clear();
                      await settings.setApiKey(null);
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('API key cleared')),
                      );
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Stored locally using secure storage.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Shared text field widget ──────────────────────────────────────────────

class _SettingsTextField extends StatelessWidget {
  const _SettingsTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}
