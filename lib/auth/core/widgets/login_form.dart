// auth/core/widgets/login_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui/controller/provider.dart' show authNotifierProvider;
import '../../ui/controller/state.dart';
import '../const/sizes.dart';
import '../utils/validator.dart';


class LoginFormContainer extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const LoginFormContainer({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;
    

    ref.listen<AuthState>(authNotifierProvider, (previous, current) {
      if (current is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(current.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    void handleLogin() {
      if (formKey.currentState!.validate()) {
        ref.read(authNotifierProvider.notifier).signIn(
              emailController.text.trim(),
              passwordController.text.trim(),
            );
      }
    }

    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(TSizes.cardRadiusLg * 2),
          topRight: Radius.circular(TSizes.cardRadiusLg * 2),
        ),
      ),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            const SizedBox(height: 50),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: TValidator.validateEmail,
            ),
            const SizedBox(height: TSizes.spaceBtwInputFields),
            TextFormField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Senha',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              validator: TValidator.validatePassword,
            ),
            const SizedBox(height: 100),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : handleLogin,
                child: isLoading
                    ? const SizedBox(
                        width: TSizes.loadingIndicatorSize / 2,
                        height: TSizes.loadingIndicatorSize / 2,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Entrar'),
              ),
            ),
            const SizedBox(height:180 ),
            TextButton(
              onPressed: () => context.goNamed('/register'),
              child: const Text('Criar Conta'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
