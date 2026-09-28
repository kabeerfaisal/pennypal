import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../utils/countries.dart';
import '../utils/phone_rule.dart';
import '../utils/session.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  CountryInfo _country = kCountries.first;
  bool _isLoading = false;
  bool _obscure = true;
  String _error = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// Digits only, so the dial code prefix and formatting never affect checks.
  String get _phoneDigits => _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');

  Future<void> _register() async {
    final digits = _phoneDigits;
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in your name, email and password');
      return;
    }
    final phoneProblem = PhoneRule.validate(digits);
    if (phoneProblem != null) {
      setState(() => _error = phoneProblem);
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final err = await _auth.register(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
      phone: '${_country.dial}$digits',
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _isLoading = false;
        _error = err;
      });
      return;
    }
    await openHomeForSession(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join PennyPal and start saving!',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 32),
              _field(_nameCtrl, 'Full Name', Icons.person_outline),
              const SizedBox(height: 14),
              DropdownButtonFormField<CountryInfo>(
                initialValue: _country,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Country code',
                  prefixIcon: Icon(Icons.public),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                items: kCountries
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.flag}  ${c.name}  ${c.dial}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _country = v);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                // A single limiter. Having both maxLength and an explicit
                // LengthLimitingTextInputFormatter made the field fight itself.
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(PhoneRule.max),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Phone number',
                  hintText: '03XXXXXXXXX',
                  helperText: _phoneDigits.isEmpty ? PhoneRule.hint : null,
                  helperMaxLines: 2,
                  errorText: _phoneDigits.isEmpty
                      ? null
                      : PhoneRule.validate(_phoneDigits),
                  suffixIcon: _phoneDigits.isEmpty
                      ? null
                      : Icon(
                          PhoneRule.isValid(_phoneDigits)
                              ? Icons.check_circle_rounded
                              : Icons.more_horiz_rounded,
                          size: 20,
                          color: PhoneRule.isValid(_phoneDigits)
                              ? const Color(0xFF16A34A)
                              : Theme.of(context).colorScheme.onSurface
                                    .withValues(alpha: 0.35),
                        ),
                  prefixText: '${_country.dial}  ',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _field(
                _emailCtrl,
                'Email',
                Icons.email_outlined,
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _error,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              _isLoading
                  ? CircularProgressIndicator(color: cs.primary)
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _register,
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}
