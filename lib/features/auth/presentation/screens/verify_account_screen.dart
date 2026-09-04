import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class VerifyAccountScreen extends ConsumerStatefulWidget {
  const VerifyAccountScreen({super.key});

  @override
  ConsumerState<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends ConsumerState<VerifyAccountScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  Future<void> _verify() async {
    if (_codeController.text.trim().length != 6) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).verifyAccount(_codeController.text.trim());
      await ref.read(authNotifierProvider.notifier).loadCurrentUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compte vérifié avec succès.')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      await ref.read(authRepositoryProvider).sendVerificationCode();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code renvoyé par email.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification du compte')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entrez le code à 6 chiffres envoyé par email.', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _codeController,
              label: 'Code de vérification',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Vérifier',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _verify,
              width: double.infinity,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _isResending ? null : _resend,
                child: Text(_isResending ? 'Envoi...' : 'Renvoyer le code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}