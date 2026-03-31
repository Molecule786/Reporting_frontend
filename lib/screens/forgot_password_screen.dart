import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _emailSent = false;
  bool _tokenVerified = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await ApiService.forgotPassword(_emailController.text.trim());
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
          _successMessage = result['message'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _verifyToken() async {
    if (_tokenController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the reset token';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.verifyResetToken(
        _emailController.text.trim(),
        _tokenController.text.trim(),
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['valid']) {
            _tokenVerified = true;
            _successMessage = 'Token verified! Please enter your new password.';
          } else {
            _errorMessage = result['message'];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.resetPassword(
        _emailController.text.trim(),
        _tokenController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _successMessage = result['message'];
        });
        
        // Show success dialog and navigate back to login
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Password Reset Successful'),
            content: const Text('Your password has been reset successfully. You can now login with your new password.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to login
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AppCard(
              padding: const EdgeInsets.all(40),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Step indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStepIndicator(1, 'Email', true),
                        _buildStepConnector(_emailSent),
                        _buildStepIndicator(2, 'Token', _emailSent),
                        _buildStepConnector(_tokenVerified),
                        _buildStepIndicator(3, 'Password', _tokenVerified),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Messages
                    if (_errorMessage != null) ...[
                      _buildMessageBanner(_errorMessage!, AppTheme.error),
                      const SizedBox(height: 24),
                    ],
                    if (_successMessage != null) ...[
                      _buildMessageBanner(_successMessage!, AppTheme.success),
                      const SizedBox(height: 24),
                    ],

                    // Step 1: Email
                    if (!_emailSent) ...[
                      const Text(
                        'Forgot your password?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Enter your email address and we\'ll send you a verification token.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      AppTextField(
                        label: 'Email Address',
                        hint: 'name@company.com',
                        controller: _emailController,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email is required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: 'Send Reset Token',
                        isLoading: _isLoading,
                        onPressed: _sendResetEmail,
                      ),
                    ],

                    // Step 2: Token verification
                    if (_emailSent && !_tokenVerified) ...[
                      const Text(
                        'Verify Identity',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We\'ve sent a token to ${_emailController.text}. Please enter it below.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      AppTextField(
                        label: 'Reset Token',
                        hint: 'Enter token from email',
                        controller: _tokenController,
                        prefixIcon: Icons.security_rounded,
                        validator: (v) => v?.isEmpty ?? true ? 'Token is required' : null,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() {
                                _emailSent = false;
                                _errorMessage = null;
                                _successMessage = null;
                              }),
                              child: const Text('Back'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppButton(
                              label: 'Verify',
                              isLoading: _isLoading,
                              onPressed: _verifyToken,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Step 3: New password
                    if (_tokenVerified) ...[
                      const Text(
                        'Set New Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Choose a strong password for your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      AppTextField(
                        label: 'New Password',
                        hint: '••••••••',
                        controller: _passwordController,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline_rounded,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          if (v.length < 6) return 'At least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        label: 'Confirm Password',
                        hint: '••••••••',
                        controller: _confirmPasswordController,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline_rounded,
                        validator: (v) => v?.isEmpty ?? true ? 'Please confirm password' : null,
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: 'Reset Password',
                        isLoading: _isLoading,
                        onPressed: _resetPassword,
                        backgroundColor: AppTheme.secondary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBanner(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(color == AppTheme.error ? Icons.error_outline : Icons.check_circle_outline, 
               size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.grey.shade200,
            shape: BoxShape.circle,
            boxShadow: isActive ? [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ] : null,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? AppTheme.primary : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 22),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}