import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ====== Config ======
  // Emulator → 10.0.2.2, Physical device → your PC LAN IP (e.g., 192.168.x.y)
  static const String baseUrl = "http://10.126.58.60:8000";
  // static const String baseUrl = "http://172.30.28.228:8000";

  // ====== State ======
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _email.text.trim(),
          "password": _password.text.trim(),
        }),
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['ok'] == true) {
          // success → go home
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        } else {
          _showSnack(data['error'] ?? 'Invalid credentials');
        }
      } else if (res.statusCode == 401) {
        _showSnack('Invalid email or password');
      } else {
        _showSnack('Server error: ${res.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnack('Network error: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32));
    return Scaffold(
      // Transparent app bar so the gradient feels roomy
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ===== Background gradient =====
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.9, -1),
                  end: Alignment(1, 1),
                  colors: [
                    Color(0xFFECF8ED),
                    Color(0xFFD7F4DE),
                    Color(0xFFC2EFD0),
                  ],
                ),
              ),
            ),

            // ===== Decorative circles =====
            Positioned(
              top: -60,
              right: -40,
              child: _blob(180, const Color(0x332E7D32)),
            ),
            Positioned(
              bottom: -50,
              left: -30,
              child: _blob(160, const Color(0x1A2E7D32)),
            ),

            // ===== Content =====
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _glassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 6),
                        // Logo / Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🐄', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 8),
                            Text(
                              'VetCare',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to continue',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),

                        // ===== Form =====
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.username, AutofillHints.email],
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                validator: (v) {
                                  final t = v?.trim() ?? '';
                                  if (t.isEmpty) return 'Email is required';
                                  if (!t.contains('@') || !t.contains('.')) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                autofillHints: const [AutofillHints.password],
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscure ? 'Show' : 'Hide',
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                validator: (v) {
                                  if ((v ?? '').length < 1) return 'Min 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _showSnack('Forgot password coming soon'),
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // ===== Login button =====
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: cs.primary,
                                    foregroundColor: cs.onPrimary,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                      : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // ===== Divider and helper text =====
                              Row(
                                children: const [
                                  Expanded(child: Divider(height: 1)),
                                  SizedBox(width: 12),
                                  Text('or'),
                                  SizedBox(width: 12),
                                  Expanded(child: Divider(height: 1)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'New here? Ask your admin to create an account or switch to the Signup page.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === UI helpers ===
  Widget _glassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 20, offset: Offset(0, 12)),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: child,
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
