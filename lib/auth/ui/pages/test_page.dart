// android/lib/auth/ui/pages/test_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/const/colors.dart';
import '../../core/const/sizes.dart';
import '../controller/provider.dart';
import '../controller/state.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuta o estado para pegar a entidade do usuário
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              // Chama o método de Logout do Notifier
              ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bem-vindo(a), ${user?.name ?? user?.email ?? 'Usuário'}!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: TColors.primary,
                      fontSize: TSizes.fontSizeLg,
                    ),
              ),
              const SizedBox(height: TSizes.spaceBtwItems),
              Text('ID do Usuário: ${user?.id ?? 'N/A'}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: TSizes.spaceBtwItems),
              const Text(
                'Esta é a tela principal. O GoRouter garantiu que você só chegasse aqui se estivesse autenticado.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBtwSections),
              ElevatedButton(
                onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, TSizes.buttonHeight * 3), 
                  backgroundColor: TColors.error,
                  foregroundColor: TColors.textWhite,
                ),
                child: const Text('Sair / Deslogar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
