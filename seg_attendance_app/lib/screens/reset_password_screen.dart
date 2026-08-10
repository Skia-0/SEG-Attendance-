import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String code;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _api = ApiService();

  bool _loading = false;
  bool _hideNew = true;
  bool _hideConfirm = true;
  int _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _newController.addListener(_updateStrength);
  }

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _updateStrength() {
    final pw = _newController.text;
    int score = 0;
    if (pw.length >= 8) score++;
    if (pw.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(pw)) score++;
    if (RegExp(r'\d').hasMatch(pw)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) score++;
    setState(() {
      _passwordStrength = score.clamp(0, 4);
    });
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a new password';
    }
    if (value.length < 8) {
      return 'Must be at least 8 characters';
    }
    if (value.length > 32) {
      return 'Must not exceed 32 characters';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Must contain at least one letter';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Must contain at least one number';
    }
    return null;
  }

  Color _strengthColor() {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return Colors.red.shade600;
      case 2:
        return Colors.orange.shade600;
      case 3:
        return Colors.amber.shade700;
      case 4:
      default:
        return Colors.green.shade700;
    }
  }

  String _strengthLabel() {
    switch (_passwordStrength) {
      case 0:
        return 'Too weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
      default:
        return 'Strong';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _api.resetPassword(
        email: widget.email,
        code: widget.code,
        newPassword: _newController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successful. Please log in.'),
          backgroundColor: Color(0xFFFF6B00),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Go back to login
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      String msg = 'Failed to reset password';
      try {
        final resp = (e as dynamic).response;
        final err = resp?.data?['error'];
        if (err != null) msg = err.toString();
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('NEW PASSWORD'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set New Password',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a new password for ${widget.email}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _newController,
                  obscureText: _hideNew,
                  maxLength: 32,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_hideNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _hideNew = !_hideNew),
                    ),
                  ),
                  validator: _validatePassword,
                ),

                if (_newController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _passwordStrength / 4,
                            minHeight: 5,
                            backgroundColor:
                                const Color(0xFFEEEEEE),
                            valueColor: AlwaysStoppedAnimation(
                              _strengthColor(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _strengthLabel(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _strengthColor(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Must be 8-32 characters, with at least '
                    'one letter and one number.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmController,
                  obscureText: _hideConfirm,
                  maxLength: 32,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_hideConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(
                          () => _hideConfirm = !_hideConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Confirm new password';
                    }
                    if (v != _newController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Reset Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}