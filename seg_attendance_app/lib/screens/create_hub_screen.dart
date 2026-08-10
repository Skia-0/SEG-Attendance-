import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'verify_otp_screen.dart';

class CreateHubScreen extends StatefulWidget {
  final String coordinatorName;
  final String coordinatorEmail;
  final String coordinatorPassword;

  const CreateHubScreen({
    super.key,
    required this.coordinatorName,
    required this.coordinatorEmail,
    required this.coordinatorPassword,
  });

  @override
  State<CreateHubScreen> createState() => _CreateHubScreenState();
}

class _CreateHubScreenState extends State<CreateHubScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hubNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _api = ApiService();
  bool _loading = false;

  @override
  void dispose() {
    _hubNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final hubResponse = await _api.createHub(
        name: _hubNameController.text.trim(),
        location: _locationController.text.trim(),
      );

      final hubId = hubResponse.data['hub_id'].toString();

      await _api.registerCoordinator(
        fullName: widget.coordinatorName,
        email: widget.coordinatorEmail,
        password: widget.coordinatorPassword,
        hubId: hubId,
      );

      if (mounted) {
        setState(() => _loading = false);
        // Go directly to OTP verification
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyOtpScreen(
              email: widget.coordinatorEmail,
              purpose: 'register',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        String msg = 'Registration failed. Please try again.';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Hub'),
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
                  'Step 2 of 2',
                  style: TextStyle(
                    color: Color(0xFFFF6B00),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hub Details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set up your hub location',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _hubNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Hub Name',
                    prefixIcon: Icon(Icons.business_outlined),
                    hintText: 'e.g. Accra Central Hub',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter the hub name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _locationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    hintText: 'e.g. Accra, Ghana',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter the hub location';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF6B00).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B00),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Name: ${widget.coordinatorName}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email: ${widget.coordinatorEmail}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You will receive a verification code by email after creating your account.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF444444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Create Account'),
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