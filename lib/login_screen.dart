import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Definisi warna yang konsisten
const Color w3Green = Color(0xFF006400);

//==================================================================
// 1. HALAMAN LOGIN (UTAMA)
//==================================================================
class LoginScreen extends StatefulWidget {
  /// Optional callback invoked when login succeeds.
  final VoidCallback? onLoginSuccess;

  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _passwordVisible = false;
  final _formKey = GlobalKey<FormState>();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    // reset inline errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        if (email.isEmpty) _emailError = 'Please enter your email';
        if (password.isEmpty) _passwordError = 'Please enter your password';
      });
      return;
    }
    // basic email format validation
    final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Invalid email format');
      return;
    }
    setState(() => _loading = true);
    try {
      // Add a small delay to ensure platform channel is ready
      await Future.delayed(const Duration(milliseconds: 100));

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Verify user credential was received
      if (userCredential.user == null) {
        throw Exception('Sign in returned null user');
      }

      // Reload to fetch latest user data (displayName, etc.) from Firebase
      try {
        await userCredential.user!.reload();
      } catch (e) {
        print('DEBUG: Error reloading user: $e');
      }

      if (!mounted) return;
      widget.onLoginSuccess?.call();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Map common Firebase errors to field-level messages
      switch (e.code) {
        case 'user-not-found':
          setState(() => _emailError = 'No user found for that email');
          break;
        case 'wrong-password':
          setState(() => _passwordError = 'Incorrect password');
          break;
        case 'invalid-email':
          setState(() => _emailError = 'Invalid email');
          break;
        case 'too-many-requests':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Too many attempts. Try later.')),
          );
          break;
        case 'user-disabled':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This user account has been disabled.'),
            ),
          );
          break;
        default:
          // Check for specific error messages
          final message = e.message ?? '';
          if (message.contains('incorrect') ||
              message.contains('malformed') ||
              message.contains('expired')) {
            setState(() => _passwordError = 'Wrong email or password');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message ?? 'Sign in failed')),
            );
          }
      }
    } catch (e) {
      if (!mounted) return;

      // Check for credential error
      if (e.toString().contains('incorrect') ||
          e.toString().contains('malformed') ||
          e.toString().contains('expired') ||
          e.toString().contains('credential')) {
        setState(() => _passwordError = 'Wrong email or password');
        return;
      }

      // Ignore platform channel type errors and consider login successful if it gets this far
      if (e.toString().contains('List<Object?>') ||
          e.toString().contains('PigeonUserDetails')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful (platform note)'),
            duration: Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        widget.onLoginSuccess?.call();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign in error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Hijau dengan Logo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                color: w3Green,
                child: Column(
                  children: const [
                    Text(
                      'W3 Grocery',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Form Putih
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                transform: Matrix4.translationValues(0, -20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- FIELD EMAIL (GAYA OUTLINE) ---
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Colors.grey.shade700,
                        ),
                        errorText: _emailError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) {
                        if (_emailError != null)
                          setState(() => _emailError = null);
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- FIELD PASSWORD (GAYA OUTLINE) ---
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.grey.shade700,
                        ),
                        errorText: _passwordError,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey.shade700,
                          ),
                          onPressed: () => setState(
                            () => _passwordVisible = !_passwordVisible,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (_) {
                        if (_passwordError != null)
                          setState(() => _passwordError = null);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Keep Sign In & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: true,
                              onChanged: (val) {},
                              activeColor: w3Green,
                            ),
                            const Text('Keep Sign In'),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(color: w3Green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tombol SIGN IN
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: w3Green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _loading ? null : _signIn,
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'SIGN IN',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol CREATE AN ACCOUNT
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: w3Green,
                          side: BorderSide(color: w3Green.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'CREATE AN ACCOUNT',
                          style: TextStyle(fontSize: 16),
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

//==================================================================
// 2. HALAMAN BUAT AKUN
//==================================================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _loading = false;
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String _accountType = 'customer'; // 'customer', 'vendor', or 'driver'

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final pwd = _passwordController.text;
    final confirm = _confirmController.text;
    final name = _nameController.text.trim();

    print('DEBUG _register started: email=$email, name=$name');

    // reset errors
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
    });

    if (email.isEmpty || pwd.isEmpty) {
      setState(() {
        if (email.isEmpty) _emailError = 'Please enter your email';
        if (pwd.isEmpty) _passwordError = 'Please enter a password';
      });
      return;
    }
    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter your full name');
      return;
    }
    if (pwd != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    print('DEBUG: All validations passed, starting registration');
    setState(() => _loading = true);
    try {
      // Add a small delay to ensure platform channel is ready
      await Future.delayed(const Duration(milliseconds: 100));

      print('DEBUG: Creating user account...');
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pwd);

      print('DEBUG: User created: ${userCredential.user?.uid}');
      // Verify user credential was received
      if (userCredential.user == null) {
        throw Exception('Registration returned null user');
      }

      // Update display name if provided
      final fullName = _nameController.text.trim();
      print('DEBUG SIGNUP: Full name from form = "$fullName"');

      if (fullName.isNotEmpty) {
        try {
          print('DEBUG: Attempting to set displayName...');
          await userCredential.user!.updateDisplayName(fullName);
          print('DEBUG: displayName updated');
          await userCredential.user!.reload();
          print('DEBUG: user reloaded');

          // Also save to SharedPreferences for reliable retrieval
          print('DEBUG: Getting SharedPreferences instance...');
          final prefs = await SharedPreferences.getInstance();
          final key = 'profile_${email}_name';
          print('DEBUG: Setting $key to: $fullName');
          final success = await prefs.setString(key, fullName);
          print('DEBUG: setString returned: $success');

          // Save account type
          final accountTypeKey = 'profile_${email}_accountType';
          await prefs.setString(accountTypeKey, _accountType);
          print('DEBUG: Saved accountType: $_accountType');

          // Verify it was saved immediately
          final verify = prefs.getString(key);
          print('DEBUG: Verified saved value: $verify');

          print('DEBUG: Display name set to: $fullName');
        } catch (e) {
          print('DEBUG: Error setting display name: $e');
          print('DEBUG: Error type: ${e.runtimeType}');
        }
      } else {
        print('DEBUG: Full name is empty!');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Account created')));
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      print('DEBUG: FirebaseAuthException: ${e.code} - ${e.message}');
      if (!mounted) return;
      switch (e.code) {
        case 'email-already-in-use':
          setState(() => _emailError = 'Email already in use');
          break;
        case 'weak-password':
          setState(() => _passwordError = 'Password is too weak');
          break;
        case 'invalid-email':
          setState(() => _emailError = 'Invalid email');
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Registration failed')),
          );
      }
    } catch (e) {
      print('DEBUG: General exception in signup: $e');
      print('DEBUG: Exception type: ${e.runtimeType}');

      // Even if there's an exception, try to set the displayName if user was created
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print(
            'DEBUG: User exists after exception, attempting to save name...',
          );
          final fullName = _nameController.text.trim();
          if (fullName.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            final key = 'profile_${email}_name';
            await prefs.setString(key, fullName);
            print(
              'DEBUG: Successfully saved $key despite exception: $fullName',
            );
          }
        }
      } catch (innerE) {
        print('DEBUG: Failed to save name in exception handler: $innerE');
      }

      if (!mounted) return;
      // Ignore platform channel type errors and consider registration successful if user exists
      if (e.toString().contains('List<Object?>') ||
          e.toString().contains('PigeonUserDetails')) {
        print('DEBUG: Platform error but user was created, proceeding...');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created (platform note)'),
            duration: Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Registration error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: w3Green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create your account',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please enter your information to create an account.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // --- FIELD FULL NAME (GAYA OUTLINE) ---
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Full Name',
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: Colors.grey.shade700,
                ),
                errorText: _nameError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            // Debug: Show what's in the name field
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Name value: ${_nameController.text}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),

            // --- FIELD EMAIL (GAYA OUTLINE) ---
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'Email',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Colors.grey.shade700,
                ),
                errorText: _emailError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
            ),
            const SizedBox(height: 16),

            // --- FIELD PASSWORD (GAYA OUTLINE) ---
            TextFormField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.grey.shade700,
                ),
                errorText: _passwordError,
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey.shade700,
                  ),
                  onPressed: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) {
                if (_passwordError != null)
                  setState(() => _passwordError = null);
              },
            ),
            const SizedBox(height: 16),

            // --- FIELD CONFIRM PASSWORD (GAYA OUTLINE) ---
            TextFormField(
              controller: _confirmController,
              obscureText: !_confirmVisible,
              decoration: InputDecoration(
                hintText: 'Confirm Password',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.grey.shade700,
                ),
                errorText: _confirmError,
                suffixIcon: IconButton(
                  icon: Icon(
                    _confirmVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey.shade700,
                  ),
                  onPressed: () =>
                      setState(() => _confirmVisible = !_confirmVisible),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) {
                if (_confirmError != null) setState(() => _confirmError = null);
              },
            ),
            const SizedBox(height: 24),

            // Account Type Selection
            Text(
              'Account Type (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _accountType == 'customer'
                          ? w3Green.withValues(alpha: 0.1)
                          : Colors.transparent,
                      side: BorderSide(
                        color: _accountType == 'customer'
                            ? w3Green
                            : Colors.grey.shade300,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => setState(() => _accountType = 'customer'),
                    child: Text(
                      'Customer',
                      style: TextStyle(
                        color: _accountType == 'customer'
                            ? w3Green
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _accountType == 'vendor'
                          ? w3Green.withValues(alpha: 0.1)
                          : Colors.transparent,
                      side: BorderSide(
                        color: _accountType == 'vendor'
                            ? w3Green
                            : Colors.grey.shade300,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => setState(() => _accountType = 'vendor'),
                    child: Text(
                      'Vendor',
                      style: TextStyle(
                        color: _accountType == 'vendor'
                            ? w3Green
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _accountType == 'driver'
                          ? w3Green.withValues(alpha: 0.1)
                          : Colors.transparent,
                      side: BorderSide(
                        color: _accountType == 'driver'
                            ? w3Green
                            : Colors.grey.shade300,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => setState(() => _accountType = 'driver'),
                    child: Text(
                      'Driver',
                      style: TextStyle(
                        color: _accountType == 'driver'
                            ? w3Green
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Tombol SIGN UP
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: w3Green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _loading ? null : _register,
                child: const Text('SIGN UP', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//==================================================================
// 3. HALAMAN LUPA PASSWORD (STEP 1: MASUKKAN EMAIL)
//==================================================================
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Controller untuk mengambil teks email
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: w3Green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reset your password',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter the email associated with your account and we\'ll send an email with instructions to reset your password.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailController, // Gunakan controller
              decoration: InputDecoration(
                hintText: 'Email',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Colors.grey.shade700,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: w3Green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  // Ambil email dari controller
                  final email = _emailController.text.trim();
                  if (email.isEmpty) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your email')),
                    );
                    return;
                  }
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(
                      email: email,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent'),
                      ),
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                  } on FirebaseAuthException catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.message ?? 'Error sending reset email'),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text(
                  'SEND INSTRUCTIONS',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//==================================================================
// 4. HALAMAN VERIFIKASI (STEP 2: MASUKKAN KODE)
//==================================================================
class VerificationScreen extends StatefulWidget {
  final String email; // Menerima email dari halaman sebelumnya
  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // Controller untuk mengambil kode
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Enter Code'),
        backgroundColor: w3Green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Check your email',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Menampilkan email yang dikirimi kode (menggunakan widget.email)
            Text(
              'We\'ve sent a 6-digit verification code to\n${widget.email}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _codeController, // Gunakan controller
              decoration: InputDecoration(
                hintText: 'Enter 6-digit code',
                prefixIcon: Icon(
                  Icons.pin_outlined,
                  color: Colors.grey.shade700,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6, // Batasi 6 digit
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, letterSpacing: 3),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: w3Green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // --- PERBAIKAN DIMULAI DI SINI ---
                  // Ambil kode dari controller
                  final code = _codeController.text;

                  // TODO: Ganti "123456" dengan logika verifikasi Anda
                  if (code == "123456") {
                    // Jika benar, navigasi ke halaman Reset Password
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ResetPasswordScreen(email: widget.email),
                      ),
                    );
                  } else {
                    // Tampilkan pesan error jika kode salah
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Verification code is incorrect.'),
                      ),
                    );
                  }
                  // --- AKHIR PERBAIKAN ---
                },
                child: const Text('VERIFY', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Didn't receive the code?"),
                TextButton(
                  onPressed: () {
                    // TODO: Tambahkan logika kirim ulang kode
                  },
                  child: const Text('Resend', style: TextStyle(color: w3Green)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//==================================================================
// 5. HALAMAN RESET PASSWORD (STEP 3: PASSWORD BARU)
//==================================================================
class ResetPasswordScreen extends StatefulWidget {
  final String email; // Menerima email
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // Controller untuk password baru
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: w3Green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create new password',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Your new password must be different from previously used passwords.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // --- FIELD PASSWORD BARU ---
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'New Password',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.grey.shade700,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- FIELD KONFIRMASI PASSWORD BARU ---
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Confirm New Password',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Colors.grey.shade700,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Tombol RESET PASSWORD
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: w3Green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  final newPassword = _passwordController.text;
                  final confirmPassword = _confirmPasswordController.text;

                  // Cek jika password sama
                  if (newPassword.isEmpty || newPassword != confirmPassword) {
                    // Tampilkan error
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passwords do not match.')),
                    );
                    return;
                  }

                  // TODO: Tambahkan logika update password di database
                  //       untuk akun dengan email: widget.email

                  // Kembali ke halaman Login (hapus semua halaman di atasnya)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false, // Hapus semua (Reset, Verify, Forgot)
                  );
                },
                child: const Text(
                  'RESET PASSWORD',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
