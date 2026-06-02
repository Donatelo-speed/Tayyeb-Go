import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/theme/app_typography.dart';
import '../../presentation/shared_widgets/animated_button.dart';

class RegisterScreen extends StatefulWidget {
  final void Function(UserModel user)? onRegistered;
  final VoidCallback? onLoginTap;

  const RegisterScreen({super.key, this.onRegistered, this.onLoginTap});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _pageCtrl = PageController();
  int _currentStep = 0;
  String _phoneNumber = '';
  UserModel? _verifiedUser;

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageCtrl.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<bool> _onWillPop() async {
    switch (_currentStep) {
      case 0:
        return true;
      case 1:
        _goToStep(0);
        return false;
      case 2:
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Skip profile setup?'),
            content: const Text(
              'You can complete your profile later from the settings screen. Your account is already active.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Skip for now', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (leave == true && mounted) {
          widget.onRegistered?.call(_verifiedUser!);
        }
        return false;
      default:
        return true;
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!await _onWillPop()) return;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F3),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () async {
                        if (await _onWillPop()) Navigator.of(context).pop();
                      },
                    ),
                    const Spacer(),
                    if (_currentStep == 2)
                      TextButton(
                        onPressed: () => widget.onRegistered?.call(_verifiedUser!),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _StepProgressBar(currentStep: _currentStep, totalSteps: 3),
              ),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _PhoneStep(onCodeSent: (phone) {
                      _phoneNumber = phone;
                      _goToStep(1);
                    }),
                    _OtpStep(
                      phoneNumber: _phoneNumber,
                      onVerified: (user) {
                        _verifiedUser = user;
                        _goToStep(2);
                      },
                      onChangeNumber: () => _goToStep(0),
                    ),
                    _ProfileStep(
                      verifiedUser: _verifiedUser,
                      onCompleted: (user) => widget.onRegistered?.call(user),
                    ),
                  ],
                ),
              ),
              if (_currentStep == 0 && widget.onLoginTap != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: AppTypography.caption),
                      GestureDetector(
                        onTap: widget.onLoginTap,
                        child: Text(
                          'Sign In',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepProgressBar({required this.currentStep, required this.totalSteps});

  static const _stepLabels = ['Phone', 'Verify', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(totalSteps * 2 - 1, (i) {
            if (i.isOdd) {
              final stepIndex = i ~/ 2;
              final isCompleted = stepIndex < currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: 2,
                  color: isCompleted ? AppColors.primary : AppColors.divider,
                ),
              );
            }
            final stepIndex = i ~/ 2;
            final isCompleted = stepIndex < currentStep;
            final isActive = stepIndex == currentStep;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 32 : 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted || isActive ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.divider,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : AppColors.textMuted,
                        ),
                      ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (i) {
            final isActive = i == currentStep;
            return Text(
              _stepLabels[i],
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            );
          }),
        ),
      ],
    );
  }
}

typedef _CC = ({String dial, String flag, String name});

const List<_CC> _codes = [
  (dial: '+971', flag: '\u{1F1E6}\u{1F1EA}', name: 'UAE'),
  (dial: '+966', flag: '\u{1F1F8}\u{1F1E6}', name: 'Saudi Arabia'),
  (dial: '+973', flag: '\u{1F1E7}\u{1F1AD}', name: 'Bahrain'),
  (dial: '+974', flag: '\u{1F1F6}\u{1F1E6}', name: 'Qatar'),
  (dial: '+965', flag: '\u{1F1F0}\u{1F1FC}', name: 'Kuwait'),
  (dial: '+968', flag: '\u{1F1F4}\u{1F1F2}', name: 'Oman'),
  (dial: '+20', flag: '\u{1F1EA}\u{1F1EC}', name: 'Egypt'),
  (dial: '+962', flag: '\u{1F1EF}\u{1F1F4}', name: 'Jordan'),
  (dial: '+961', flag: '\u{1F1F1}\u{1F1E7}', name: 'Lebanon'),
  (dial: '+44', flag: '\u{1F1EC}\u{1F1E7}', name: 'UK'),
  (dial: '+1', flag: '\u{1F1FA}\u{1F1F8}', name: 'USA / Canada'),
];

class _PhoneStep extends StatefulWidget {
  final void Function(String e164Phone) onCodeSent;
  const _PhoneStep({required this.onCodeSent});

  @override
  State<_PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends State<_PhoneStep> {
  _CC _selectedCode = _codes.first;
  final _phoneCtrl = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone => '${_selectedCode.dial}${_phoneCtrl.text.trim()}';

  Future<void> _send() async {
    final n = _phoneCtrl.text.trim();
    if (n.isEmpty) {
      setState(() => _error = 'Please enter your phone number');
      return;
    }
    if (n.length < 7) {
      setState(() => _error = 'Enter a valid phone number (minimum 7 digits)');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final success = await context.read<AuthProvider>().verifyPhoneNumber(_fullPhone);
    if (!mounted) return;
    if (success) {
      setState(() => _sending = false);
      widget.onCodeSent(_fullPhone);
    } else {
      final err = context.read<AuthProvider>().error;
      setState(() {
        _sending = false;
        _error = err ?? 'Failed to send verification code.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.phone_outlined, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text("What's your number?", style: AppTypography.heading2),
          const SizedBox(height: 6),
          Text(
            "We'll send a one-time verification code to confirm it's you.",
            style: AppTypography.caption,
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CountryCodePicker(
                selected: _selectedCode,
                onChanged: (c) => setState(() => _selectedCode = c),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  onSubmitted: (_) => _sending ? null : _send(),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: InputDecoration(
                    labelText: 'Phone number',
                    hintText: '501 234 567',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            _InlineError(_error!),
          ],
          const SizedBox(height: 28),
          AnimatedButton(
            onPressed: _send,
            isLoading: _sending,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sms_outlined, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text('Send Verification Code'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpStep extends StatefulWidget {
  final String phoneNumber;
  final void Function(UserModel user) onVerified;
  final VoidCallback onChangeNumber;

  const _OtpStep({
    required this.phoneNumber,
    required this.onVerified,
    required this.onChangeNumber,
  });

  @override
  State<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends State<_OtpStep> {
  String _code = '';
  bool _verifying = false;
  String? _error;
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _secondsLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _verify() async {
    if (_code.length < 6) {
      setState(() => _error = 'Please enter the 6-digit code');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    final success = await context.read<AuthProvider>().verifyOtpCode(_code);
    if (!mounted) return;
    setState(() => _verifying = false);
    if (success) {
      _timer?.cancel();
      final user = context.read<AuthProvider>().user;
      if (user != null) widget.onVerified(user);
    } else {
      final err = context.read<AuthProvider>().error;
      setState(() => _error = err ?? 'Invalid code. Please try again.');
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _resend() async {
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyPhoneNumber(widget.phoneNumber);
    if (!mounted) return;
    if (success) {
      setState(() {
        _code = '';
        _error = null;
      });
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New code sent'), behavior: SnackBarBehavior.floating),
      );
    } else {
      setState(() => _error = auth.error ?? 'Failed to resend code.');
    }
  }

  String get _maskedPhone {
    final p = widget.phoneNumber;
    if (p.length <= 6) return p;
    final dialEnd = p.startsWith('+') ? (p.indexOf(RegExp(r'\d')) + 3) : 0;
    final visible = p.substring(p.length - 3);
    final stars = '\u2022' * (p.length - dialEnd - 3);
    return '${p.substring(0, dialEnd)}$stars$visible';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.shield_outlined, size: 32, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 20),
          Text('Check your messages', style: AppTypography.heading2),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: AppTypography.caption,
              children: [
                const TextSpan(text: 'Enter the 6-digit code sent to '),
                TextSpan(
                  text: _maskedPhone,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          PinCodeTextField(
            appContext: context,
            length: 6,
            animationType: AnimationType.scale,
            animationDuration: const Duration(milliseconds: 150),
            keyboardType: TextInputType.number,
            autoFocus: true,
            enableActiveFill: true,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(10),
              fieldHeight: 56,
              fieldWidth: 48,
              activeFillColor: Colors.white,
              inactiveFillColor: AppColors.background,
              selectedFillColor: Colors.white,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.divider,
              selectedColor: AppColors.primary,
              errorBorderColor: AppColors.error,
            ),
            cursorColor: AppColors.primary,
            onChanged: (v) {
              setState(() {
                _code = v;
                if (_error != null && v.length < 6) _error = null;
              });
            },
            onCompleted: (_) => _verify(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            _InlineError(_error!),
          ],
          const SizedBox(height: 20),
          AnimatedButton(
            onPressed: _verify,
            isLoading: _verifying,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_outlined, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text('Verify Code'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_secondsLeft > 0) ...[
                Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('Resend in ${_secondsLeft}s', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ] else
                TextButton(onPressed: _resend, child: const Text('Resend Code')),
              const SizedBox(width: 8),
              Text('\u00B7', style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(width: 8),
              TextButton(onPressed: widget.onChangeNumber, child: const Text('Change number')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStep extends StatefulWidget {
  final UserModel? verifiedUser;
  final void Function(UserModel user) onCompleted;

  const _ProfileStep({required this.verifiedUser, required this.onCompleted});

  @override
  State<_ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<_ProfileStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = widget.verifiedUser;
    if (user == null) {
      setState(() => _error = 'Session error. Please restart registration.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final name = _nameCtrl.text.trim();
    await context.read<AuthProvider>().updateProfile(displayName: name);

    if (!mounted) return;

    final err = context.read<AuthProvider>().error;
    if (err != null) {
      setState(() {
        _saving = false;
        _error = err;
      });
      return;
    }

    setState(() => _saving = false);
    final finalUser = context.read<AuthProvider>().user;
    widget.onCompleted(finalUser ?? user);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Icon(Icons.person_outline, size: 40, color: AppColors.primary),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF8F6F3), width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Add photo later',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 24),
            Text('Tell us about yourself', style: AppTypography.heading2),
            const SizedBox(height: 6),
            Text(
              'Your name appears on orders so restaurants and drivers know who to look for.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              style: AppTypography.body,
              decoration: InputDecoration(
                labelText: 'Full name *',
                hintText: 'Sara Al-Mansouri',
                prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your name';
                if (v.trim().length < 2) return 'Name must be at least 2 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              style: AppTypography.body,
              onFieldSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: 'Email address (optional)',
                hintText: 'you@example.com',
                helperText: 'For order receipts and account recovery',
                prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final t = v.trim();
                if (!t.contains('@') || !t.contains('.')) return 'Enter a valid email or leave it empty';
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              _InlineError(_error!),
            ],
            const SizedBox(height: 28),
            AnimatedButton(
              onPressed: _save,
              isLoading: _saving,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rocket_launch_outlined, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Start Using TayyebGo'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryCodePicker extends StatelessWidget {
  final _CC selected;
  final void Function(_CC) onChanged;
  const _CountryCodePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      constraints: const BoxConstraints(minWidth: 90),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_CC>(
          value: selected,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          borderRadius: BorderRadius.circular(10),
          items: _codes
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.flag} ${c.dial}', style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
          onChanged: (c) {
            if (c != null) onChanged(c);
          },
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 13, color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
