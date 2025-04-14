import 'package:flutter/material.dart';
import 'package:mantramind/services/supabase_service.dart';
import 'package:mantramind/screens/assessment/diagnised_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscurePassword = true;
  bool _isObscureConfirmPassword = true;
  String? _errorMessage;
  bool _isSignedUp = false;
  bool _isCheckingVerification = false;
  bool _verificationTimerActive = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _isSignedUp 
            ? _buildVerificationUI() 
            : _buildSignupForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Join MantraMind',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Create an account to start your wellness journey',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          // Name Field
          TextFormField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Enter your full name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _isObscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Create a password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: !_isLoading
                    ? () {
                        setState(() {
                          _isObscurePassword = !_isObscurePassword;
                        });
                      }
                    : null,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _isObscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Confirm your password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: !_isLoading
                    ? () {
                        setState(() {
                          _isObscureConfirmPassword = !_isObscureConfirmPassword;
                        });
                      }
                    : null,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            enabled: !_isLoading,
          ),
          const SizedBox(height: 32),
          // Signup Button
          ElevatedButton(
            onPressed: !_isLoading ? _handleSignup : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
          const SizedBox(height: 16),
          // Login Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Already have an account?"),
              TextButton(
                onPressed: !_isLoading
                    ? () {
                        Navigator.of(context).pop();
                      }
                    : null,
                child: const Text('Log In'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_unread_outlined,
          size: 80,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 24),
        Text(
          'Verify Your Email',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ve sent a verification email to:',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _emailController.text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          'Please check your inbox and click the verification link to complete your registration.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isCheckingVerification ? null : _checkEmailVerification,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isCheckingVerification
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'I\'ve Verified My Email',
                  style: TextStyle(fontSize: 16),
                ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _isCheckingVerification ? null : _resendVerificationEmail,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Resend Verification Email'),
        ),
        const SizedBox(height: 24),
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade800),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Future<void> _handleSignup() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final response = await SupabaseService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );

        if (response.user != null) {
          print('User signed up successfully: ${response.user!.id}');
          
          // Show verification UI instead of navigating away
          setState(() {
            _isLoading = false;
            _isSignedUp = true;
          });
          
          // Start verification check cycle
          _startVerificationChecks();
        } else {
          print('Signup failed');
          setState(() {
            _errorMessage = 'Failed to create account. Please try again.';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _startVerificationChecks() {
    // Start periodic checks
    _verificationTimerActive = true;
    _runVerificationCheck();
  }

  Future<void> _runVerificationCheck() async {
    if (!_verificationTimerActive) return;

    // Check verification status every 5 seconds
    await Future.delayed(const Duration(seconds: 5));
    
    if (!mounted) return;
    
    try {
      // Try using both verification methods
      bool isVerified = await SupabaseService.isEmailVerified();
      
      // If first method failed, try the alternative method
      if (!isVerified) {
        isVerified = await SupabaseService.checkEmailVerificationStatus(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      
      if (isVerified) {
        // Email is verified, proceed to next screen
        if (mounted) {
          await _proceedToNextScreen();
        }
      } else if (_verificationTimerActive && mounted) {
        // Continue checking
        _runVerificationCheck();
      }
    } catch (e) {
      print('Error checking verification: $e');
      // Continue checking despite errors
      if (_verificationTimerActive && mounted) {
        _runVerificationCheck();
      }
    }
  }

  Future<void> _checkEmailVerification() async {
    setState(() {
      _isCheckingVerification = true;
      _errorMessage = null;
    });

    try {
      // First try the standard verification method
      bool isVerified = await SupabaseService.isEmailVerified();
      
      // If that doesn't work, try the alternative method
      if (!isVerified) {
        isVerified = await SupabaseService.checkEmailVerificationStatus(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      
      if (isVerified) {
        // Email is verified, proceed to next screen
        if (mounted) {
          await _proceedToNextScreen();
        }
      } else {
        // Email is not verified yet
        if (mounted) {
          setState(() {
            _errorMessage = 'Your email is not verified yet. Please check your inbox and click the verification link.';
            _isCheckingVerification = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error checking verification status: ${e.toString()}';
          _isCheckingVerification = false;
        });
      }
    }
  }

  Future<void> _proceedToNextScreen() async {
    // Sign in the user to ensure we have a valid session
    try {
      await SupabaseService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Stop the verification timer
      _verificationTimerActive = false;
      
      // Navigate to the next screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DiagnosedPage(),
          ),
        );
      }
    } catch (e) {
      print('Error signing in after verification: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Verification confirmed, but error signing in: ${e.toString()}';
          _isCheckingVerification = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isCheckingVerification = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.resendVerificationEmail(_emailController.text.trim());
      
      if (mounted) {
        setState(() {
          _errorMessage = 'Verification email resent. Please check your inbox.';
          _isCheckingVerification = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error resending verification email: ${e.toString()}';
          _isCheckingVerification = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _verificationTimerActive = false;
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}