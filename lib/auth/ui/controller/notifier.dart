// auth/ui/controller/notifier.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod/legacy.dart';
import '../../data/repository_impl.dart';
import 'state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepositoryImpl repository;
  late final StreamSubscription<User?> _authStateSubscription;

  AuthNotifier(this.repository) : super(const AuthInitial()) {
    // Comece com AuthInitial ao invés de Loading
    _initAuthState();
  }

  Future<void> _initAuthState() async {
    debugPrint('_initAuthState called');
    try {
      state = const AuthLoading();

      final userEntity = await repository.getCurrentUser();
      debugPrint('_initAuthState userEntity: $userEntity');

      if (userEntity != null) {
        state = AuthAuthenticated(userEntity);
        debugPrint('New state after _initAuthState: $state');
      } else {
        state = const AuthInitial();
        debugPrint('New state after _initAuthState: $state');
      }

      _authStateSubscription = repository.authStateChanges.listen((user) async {
        if (user == null) {
          state = const AuthInitial();
        } else {
          try {
            final userEntity = await repository.getCurrentUser();
            if (userEntity != null) {
              state = AuthAuthenticated(userEntity);
              debugPrint('New state after _initAuthState: $state');
            }
          } catch (e) {
            state = AuthError(e.toString());
          }
        }
      });
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  Future<void> signIn(String email, String password) async {
    try {
      state = const AuthLoading();

      final userEntity = await repository.signIn(email, password);

      if (userEntity != null) {
        state = AuthAuthenticated(userEntity);
      } else {
        state = const AuthError(
          'Usuário autenticado, mas dados do perfil não encontrados.',
        );
        await repository.signOut();
      }
    } on FirebaseAuthException catch (e) {
      state = AuthError(e.message ?? 'Erro de login desconhecido.');
    } catch (e) {
      state = AuthError("Erro inesperado durante o login: ${e.toString()}");
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    try {
      state = const AuthLoading();

      final userEntity = await repository.signUp(name, email, password);

      if (userEntity != null) {
        state = AuthAuthenticated(userEntity);
      } else {
        state = const AuthError(
          'Cadastro realizado, mas dados do perfil não puderam ser criados.',
        );
        await repository.signOut();
      }
    } on FirebaseAuthException catch (e) {
      state = AuthError(e.message ?? 'Erro de cadastro desconhecido.');
    } catch (e) {
      state = AuthError("Erro inesperado durante o cadastro: ${e.toString()}");
    }
  }

  Future<void> signOut() async {
    try {
      state = const AuthLoading();
      await repository.signOut();
    } catch (e) {
      state = AuthError("An error occurred during sign out: ${e.toString()}");
    }
  }
}
