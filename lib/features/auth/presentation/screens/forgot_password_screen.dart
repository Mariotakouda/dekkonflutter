import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;

  Future<void> _sendCode() async {
    if (_emailController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_emailController.text.trim());
      setState(() => _codeSent = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Un code de réinitialisation a été envoyé par email.')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: _emailController.text.trim(),
            token: _tokenController.text.trim(),
            password: _passwordController.text,
            passwordConfirmation: _confirmController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe réinitialisé. Connectez-vous.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _codeSent
                    ? 'Entrez le code reçu et votre nouveau mot de passe.'
                    : 'Entrez votre email pour recevoir un code de réinitialisation.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                enabled: !_codeSent,
              ),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _tokenController,
                  label: 'Code reçu par email',
                  validator: (v) => Validators.required(v, field: 'Le code'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Nouveau mot de passe',
                  obscureText: true,
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmController,
                  label: 'Confirmer le mot de passe',
                  obscureText: true,
                  validator: (v) => Validators.confirmPassword(v, _passwordController.text),
                ),
              ],
              const SizedBox(height: 24),
              CustomButton(
                label: _codeSent ? 'Réinitialiser le mot de passe' : 'Envoyer le code',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : (_codeSent ? _resetPassword : _sendCode),
                width: double.infinity,
              ),
              if (_codeSent) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _sendCode,
                    child: const Text('Renvoyer le code'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}