import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  final String purpose;

  const VerifyOtpScreen({
    super.key,
    required this.email,
    required this.purpose,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _codeController = TextEditingController();
  final _api = ApiService();
  bool _loading = false;
  bool _resending = false;
  int _resendCooldown = 0;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showError('Please enter the 6-digit code');
      return;
    }

    setState(() => _loading = true);

    if (widget.purpose == 'register') {
      final error = await context
          .read<AuthProvider>()
          .verifyEmailAndLogin(widget.email, code);

      if (!mounted) return;
      setState(() => _loading = false);

      if (error == null) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      } else {
        _showError(error);
      }
    } else {
      try {
        await _api.verifyOtp(
          email: widget.email,
          code: code,
          purpose: widget.purpose,
        );

        if (!mounted) return;
        setState(() => _loading = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              email: widget.email,
              code: code,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _loading = false);

        String msg = 'Invalid code';
        try {
          final resp = (e as dynamic).response;
          final err = resp?.data?['error'];
          if (err != null) msg = err.toString();
        } catch (_) {}

        _showError(msg);
      }
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;
    setState(() => _resending = true);

    try {
      await _api.resendOtp(
        email: widget.email,
        purpose: widget.purpose,
      );
      if (mounted) {
        _showSuccess('New code sent to your email');
        _startResendCooldown();
      }
    } catch (_) {
      if (mounted) _showError('Failed to resend. Try again.');
    }

    if (mounted) setState(() => _resending = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF6B00),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = widget.purpose == 'register';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('VERIFY EMAIL'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: Color(0xFFFF6B00),
                  size: 50,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Check Your Email',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text: 'We sent a 6-digit code to\n',
                      ),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                  color: Color(0xFF1A1A1A),
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  hintStyle: TextStyle(
                    letterSpacing: 12,
                    color: Color(0xFFDDDDDD),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.shade200,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFFFF6B00),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Code expires soon. Check your spam folder if not received.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verify,
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isRegister ? 'Verify & Sign In' : 'Continue',
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive code? ",
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 13,
                    ),
                  ),
                  TextButton(
                    onPressed: (_resending || _resendCooldown > 0)
                        ? null
                        : _resend,
                    child: Text(
                      _resendCooldown > 0
                          ? 'Resend in ${_resendCooldown}s'
                          : _resending
                              ? 'Sending...'
                              : 'Resend',
                      style: TextStyle(
                        color: _resendCooldown > 0
                            ? Colors.grey
                            : const Color(0xFFFF6B00),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}