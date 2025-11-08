// test/ui/controller/notifier_test.dart

import 'dart:async';
import 'package:auth/auth/domain/entities/user_entity.dart';
import 'package:auth/auth/ui/controller/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auth/auth/ui/controller/notifier.dart';
import 'package:auth/auth/ui/controller/state.dart';
import 'package:auth/auth/data/repository_impl.dart';

final UserEntity _dummyUserEntity = UserEntity(
  id: 'dummy',
  email: 'dummy@test.com',
  name: 'Dummy',
);

class MockAuthRepositoryImpl extends Mock implements AuthRepositoryImpl {}

class MockUser extends Mock implements User {}

void main() {
  late MockAuthRepositoryImpl mockRepository;
  late ProviderContainer container;
  late UserEntity testUserEntity;
  late StreamController<User?> authStateController;

  const String testEmail = 'test@example.com';
  const String testPassword = 'password123';
  const String testName = 'Test User';
  const String testUid = 'user_uid_123';
  const String firebaseErrorMessage = 'Error-code-test';

  setUpAll(() {
    registerFallbackValue(_dummyUserEntity);
    registerFallbackValue(const AuthInitial());
    registerFallbackValue(Stream<User?>.empty());
  });

  setUp(() {
    testUserEntity = UserEntity(id: testUid, email: testEmail, name: testName);
    mockRepository = MockAuthRepositoryImpl();
    authStateController = StreamController<User?>();

    when(
      () => mockRepository.authStateChanges,
    ).thenAnswer((_) => authStateController.stream);

    container = ProviderContainer(
      overrides: [Provider<AuthRepositoryImpl>((ref) => mockRepository)],
    );
  });

  tearDown(() {
    authStateController.close();
    container.dispose();
  });

  AuthNotifier getNotifier() => container.read(authNotifierProvider.notifier);

  group('AuthNotifier Initialization (_initAuthState)', () {
    test('DEVE autenticar se o getCurrentUser retornar um usuário', () async {
      when(
        () => mockRepository.getCurrentUser(),
      ).thenAnswer((_) async => testUserEntity);

      final listener = container.listen<AuthState>(
        authNotifierProvider,
        (_, __) {},
      );

      final notifier = getNotifier();

      await Future.delayed(Duration.zero);

      expect(notifier.state, isA<AuthAuthenticated>());
      final finalState = notifier.state as AuthAuthenticated;
      expect(finalState.user, equals(testUserEntity));

      verify(() => mockRepository.getCurrentUser()).called(1);
    });

    test(
      'DEVE retornar AuthInitial se o getCurrentUser retornar nulo',
      () async {
        when(
          () => mockRepository.getCurrentUser(),
        ).thenAnswer((_) async => null);

        final listener = container.listen<AuthState>(
          authNotifierProvider,
          (_, __) {},
        );

        final notifier = getNotifier();
        await Future.delayed(Duration.zero);

        expect(notifier.state, isA<AuthInitial>());
        verify(() => mockRepository.getCurrentUser()).called(1);
      },
    );

    test('DEVE retornar AuthError se o getCurrentUser falhar', () async {
      when(
        () => mockRepository.getCurrentUser(),
      ).thenThrow(Exception('Init failed'));

      final listener = container.listen<AuthState>(
        authNotifierProvider,
        (_, __) {},
      );

      final notifier = getNotifier();
      await Future.delayed(Duration.zero);

      expect(notifier.state, isA<AuthError>());
      final errorState = notifier.state as AuthError;
      expect(errorState.message, contains('Init failed'));
    });
  });

  group('AuthNotifier Authentication Methods', () {
    setUp(() {
      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => null);

      getNotifier();

      container.listen<AuthState>(authNotifierProvider, (_, __) {});
    });

    test('signIn: DEVE autenticar com sucesso', () async {
      when(
        () => mockRepository.signIn(testEmail, testPassword),
      ).thenAnswer((_) async => testUserEntity);

      final notifier = getNotifier();
      await notifier.signIn(testEmail, testPassword);

      expect(notifier.state, isA<AuthAuthenticated>());
      expect(
        (notifier.state as AuthAuthenticated).user,
        equals(testUserEntity),
      );
    });

    test(
      'signIn: DEVE retornar AuthError em caso de FirebaseAuthException',
      () async {
        final exception = FirebaseAuthException(
          code: 'user-not-found',
          message: firebaseErrorMessage,
        );
        when(
          () => mockRepository.signIn(testEmail, testPassword),
        ).thenThrow(exception);

        final notifier = getNotifier();
        await notifier.signIn(testEmail, testPassword);

        expect(notifier.state, isA<AuthError>());
        expect(
          (notifier.state as AuthError).message,
          equals(firebaseErrorMessage),
        );
        verifyNever(() => mockRepository.signOut());
      },
    );

    test(
      'signIn: DEVE retornar AuthError e chamar signOut se o perfil for nulo',
      () async {
        when(
          () => mockRepository.signIn(testEmail, testPassword),
        ).thenAnswer((_) async => null);
        when(() => mockRepository.signOut()).thenAnswer((_) async {});

        final notifier = getNotifier();
        await notifier.signIn(testEmail, testPassword);

        expect(notifier.state, isA<AuthError>());
        expect(
          (notifier.state as AuthError).message,
          contains('dados do perfil não encontrados'),
        );

        verify(() => mockRepository.signOut()).called(1);
      },
    );

    test('signUp: DEVE cadastrar e autenticar com sucesso', () async {
      when(
        () => mockRepository.signUp(testName, testEmail, testPassword),
      ).thenAnswer((_) async => testUserEntity);

      final notifier = getNotifier();
      await notifier.signUp(testName, testEmail, testPassword);

      expect(notifier.state, isA<AuthAuthenticated>());
      expect(
        (notifier.state as AuthAuthenticated).user,
        equals(testUserEntity),
      );
    });

    test(
      'signUp: DEVE retornar AuthError em caso de FirebaseAuthException',
      () async {
        final exception = FirebaseAuthException(
          code: 'weak-password',
          message: firebaseErrorMessage,
        );
        when(
          () => mockRepository.signUp(testName, testEmail, testPassword),
        ).thenThrow(exception);

        final notifier = getNotifier();
        await notifier.signUp(testName, testEmail, testPassword);

        expect(notifier.state, isA<AuthError>());
        expect(
          (notifier.state as AuthError).message,
          equals(firebaseErrorMessage),
        );
      },
    );

    test('signOut: DEVE retornar AuthError se o signOut falhar', () async {
      when(
        () => mockRepository.signOut(),
      ).thenThrow(Exception('SignOut failed'));

      final notifier = getNotifier();
      await notifier.signOut();

      expect(notifier.state, isA<AuthError>());
      expect((notifier.state as AuthError).message, contains('SignOut failed'));
    });
  });
}
