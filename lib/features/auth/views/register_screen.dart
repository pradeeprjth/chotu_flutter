import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  bool _hasSubmitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Password strength calculation
  double _getPasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    return score / 5;
  }

  Color _getPasswordStrengthColor(double strength) {
    if (strength < 0.3) return Colors.red;
    if (strength < 0.6) return Colors.orange;
    return Colors.green;
  }

  String _getPasswordStrengthText(double strength) {
    if (strength == 0) return '';
    if (strength < 0.3) return 'Weak';
    if (strength < 0.6) return 'Medium';
    return 'Strong';
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    final cleanPhone = value.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length != 10) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    setState(() {
      _hasSubmitted = true;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
      name: _nameController.text.trim(),
      phone: _phoneController.text.replaceAll(RegExp(r'\D'), ''),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      // Show welcome message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to Chotu! Add your delivery address to start shopping.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      context.go('/home');
    }
  }

  void _showTermsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: const Text(
                  '''Terms and Conditions

1. Acceptance of Terms
By using the Chotu app, you agree to these terms and conditions.

2. User Account
You are responsible for maintaining the confidentiality of your account credentials.

3. Orders and Payments
All orders are subject to availability. Payment must be made at the time of order or upon delivery (COD).

4. Delivery
We strive to deliver within the estimated time but cannot guarantee exact delivery times.

5. Cancellation and Refunds
Orders can be cancelled before they are dispatched. Refunds will be processed within 5-7 business days.

6. Privacy
Your personal information is protected according to our Privacy Policy.

7. Changes to Terms
We reserve the right to modify these terms at any time.

For questions, please contact support@chotu.com''',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _termsAccepted = true;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Accept'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final passwordStrength = _getPasswordStrength(_passwordController.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/auth/login'),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWeb = constraints.maxWidth > 600;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: isWeb ? 400 : double.infinity,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            const Icon(
                              Icons.person_add,
                              size: 48,
                              color: Color(0xFF4CAF50),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Join Chotu',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your account to get started',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Name field
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                hintText: 'Enter your full name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              validator: _validateName,
                              onChanged: (_) {
                                if (authState.error != null) {
                                  ref.read(authProvider.notifier).clearError();
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // Phone field
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                hintText: 'Enter your phone number',
                                prefixIcon: Icon(Icons.phone_outlined),
                                prefixText: '+91 ',
                              ),
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              validator: _validatePhone,
                              onChanged: (_) {
                                if (authState.error != null) {
                                  ref.read(authProvider.notifier).clearError();
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email field (optional)
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email (Optional)',
                                hintText: 'Enter your email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: _validateEmail,
                              onChanged: (_) {
                                if (authState.error != null) {
                                  ref.read(authProvider.notifier).clearError();
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Create a strong password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: _validatePassword,
                              onChanged: (_) {
                                setState(() {}); // Update password strength
                                if (authState.error != null) {
                                  ref.read(authProvider.notifier).clearError();
                                }
                              },
                            ),

                            // Password strength indicator
                            if (_passwordController.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: passwordStrength,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _getPasswordStrengthColor(passwordStrength),
                                        ),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getPasswordStrengthText(passwordStrength),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getPasswordStrengthColor(passwordStrength),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '8+ characters, uppercase, lowercase, number',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),

                            // Confirm password field
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                hintText: 'Re-enter your password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                              validator: _validateConfirmPassword,
                              onFieldSubmitted: (_) => _handleRegister(),
                            ),
                            const SizedBox(height: 16),

                            // Terms checkbox
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _termsAccepted,
                                    onChanged: (value) {
                                      setState(() {
                                        _termsAccepted = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _showTermsDialog,
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                        ),
                                        children: const [
                                          TextSpan(text: 'I agree to the '),
                                          TextSpan(
                                            text: 'Terms & Conditions',
                                            style: TextStyle(
                                              color: Color(0xFF4CAF50),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (_hasSubmitted && !_termsAccepted)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Please accept the Terms & Conditions',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Error message
                            if (authState.error != null && authState.error!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        authState.error!,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            if (authState.error != null && authState.error!.isNotEmpty)
                              const SizedBox(height: 16),

                            // Register button
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleRegister,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text('Create Account'),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Login link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account? '),
                                TextButton(
                                  onPressed: () {
                                    context.go('/auth/login');
                                  },
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
