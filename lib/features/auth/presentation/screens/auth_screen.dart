import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import 'auth_success_screen.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final bool startInLoginMode;

  const AuthScreen({super.key, this.startInLoginMode = true});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late bool _isLoginMode = widget.startInLoginMode;
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authNotifierProvider.notifier);

    if (_isLoginMode) {
      await notifier.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      await notifier.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );
    }

    if (!mounted) return;

    final state = ref.read(authNotifierProvider);

    if (state.isAuthenticated) {
      if (!_isLoginMode) {
        // Inscription réussie : passe par l'écran de succès dédié
        // ("succès_authentification_dekkon") avant l'accueil.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthSuccessScreen()),
        );
        return;
      }
      final isEmployee = state.user?.isEmployee ?? false;
      context.go(isEmployee ? AppRoutes.adminDashboard : AppRoutes.home);
    } else if (state.status == AuthStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage ?? 'Une erreur est survenue.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final hasError = authState.status == AuthStatus.error;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          context.go(AppRoutes.home);
                        }
                      },
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.ambientShadow,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // En-tête / logo
                          Column(
                            children: [
                              Icon(Icons.shopping_bag_rounded,
                                  size: 40, color: AppColors.primary),
                              const SizedBox(height: 8),
                              Text('Dekkon',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.h1Mobile
                                      .copyWith(color: AppColors.primary)),
                              const SizedBox(height: 16),
                              if (_isLoginMode) ...[
                                Text(
                                  'Bienvenue',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.h2,
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(
                                _isLoginMode
                                    ? 'Connectez-vous pour accéder à votre espace'
                                    : 'Créez votre compte pour commencer',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          if (!_isLoginMode) ...[
                            CustomTextField(
                              controller: _firstNameController,
                              label: 'Prénom',
                              hint: 'Ex : Koffi',
                              prefixIcon: const Icon(Icons.person_outline,
                                  color: AppColors.outline),
                              validator: (v) =>
                                  Validators.required(v, field: 'Le prénom'),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _lastNameController,
                              label: 'Nom',
                              hint: 'Ex : Mensah',
                              prefixIcon: const Icon(Icons.person_outline,
                                  color: AppColors.outline),
                              validator: (v) =>
                                  Validators.required(v, field: 'Le nom'),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _phoneController,
                              label: 'Téléphone',
                              hint: '+228XXXXXXXX',
                              keyboardType: TextInputType.phone,
                              prefixIcon: const Icon(Icons.call_outlined,
                                  color: AppColors.outline),
                              validator: Validators.phone,
                            ),
                            const SizedBox(height: 16),
                          ],

                          CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: _isLoginMode ? 'nom@exemple.com' : 'jean.dupont@exemple.fr',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(
                              Icons.mail_outline,
                              color: AppColors.outline,
                            ),
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            controller: _passwordController,
                            label: 'Mot de passe',
                            hint: '••••••••',
                            obscureText: _obscurePassword,
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: hasError ? AppColors.error : AppColors.outline,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            validator: Validators.password,
                          ),

                          if (hasError) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 14, color: AppColors.error),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    authState.errorMessage ??
                                        'Identifiants invalides. Veuillez réessayer.',
                                    style: AppTextStyles.labelSmall
                                        .copyWith(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          if (!_isLoginMode) ...[
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirmer le mot de passe',
                              hint: '••••••••',
                              obscureText: _obscureConfirmPassword,
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: AppColors.outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () => setState(() =>
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword),
                              ),
                              validator: (v) => Validators.confirmPassword(
                                  v, _passwordController.text),
                            ),
                          ],

                          if (_isLoginMode) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen()),
                                ),
                                child: const Text('Mot de passe oublié ?'),
                              ),
                            ),
                          ],

                          if (!_isLoginMode) ...[
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: RichText(
                                      text: TextSpan(
                                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                                        children: [
                                          const TextSpan(text: "J'accepte les "),
                                          TextSpan(
                                            text: 'conditions générales d\'utilisation',
                                            style: const TextStyle(
                                              color: AppColors.secondary,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 20),

                          CustomButton(
                            label: _isLoginMode ? 'Se connecter' : 'Créer mon compte',
                            onPressed: (isLoading || (!_isLoginMode && !_acceptTerms)) ? null : _submit,
                            isLoading: isLoading,
                            width: double.infinity,
                          ),

                          const SizedBox(height: 20),

                          Center(
                            child: TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () =>
                                      setState(() => _isLoginMode = !_isLoginMode),
                              child: Text(
                                _isLoginMode
                                    ? 'Nouveau sur Dekkon ? Créer un compte'
                                    : 'Vous avez déjà un compte ? Se connecter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}