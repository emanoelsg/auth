// test/data/repository_impl_test.dart
// Para o teste funcionar em um ambiente isolado, precisamos definir
// as classes de domínio esperadas pelo repositório.

// ignore_for_file: subtype_of_sealed_class

// Dummies para simular as classes de domínio ausentes
import 'dart:async';
import 'package:auth/auth/data/repository_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Dummies para simular classes de domínio (AuthRepository e UserEntity)
class UserEntity {
  final String id;
  final String email;
  final String name;
  // A classe UserEntity agora inclui toString() para facilitar a depuração.
  const UserEntity({required this.id, required this.email, required this.name});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity &&
        other.id == id &&
        other.email == email &&
        other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ name.hashCode;

  @override
  String toString() => 'UserEntity(id: $id, email: $email, name: $name)';
}

abstract class AuthRepository {
  Future<UserEntity?> signUp(String name, String email, String password);
  // CORREÇÃO: O segundo parâmetro deve ser 'password'
  Future<UserEntity?> signIn(String email, String password);
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
}
// Fim dos Dummies

// Importa a classe a ser testada (Ajuste o import real no seu projeto)
// Se o seu projeto estiver estruturado como "auth/auth/data/repository_impl.dart",
// você precisará ajustar o caminho relativo para o seu ambiente de teste.

// 1. Definição dos Mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

// 2. Definição de Dados de Teste
const String testUid = 'test-uid';
const String testEmail = 'test@example.com';
const String testPassword = 'password123';
const String testName = 'Test User';
const Map<String, dynamic> testUserData = {
  'name': testName,
  'email': testEmail,
};
final expectedUserEntity = UserEntity(
  id: testUid,
  email: testEmail,
  name: testName,
);

void main() {
  // Instâncias dos Mocks
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late AuthRepositoryImpl repository;

  // Mocks de Componentes de Firebase
  late MockUser mockUser;
  late MockUserCredential mockCredential;
  late MockCollectionReference mockCollectionReference;
  late MockDocumentReference mockDocumentReference;
  late MockDocumentSnapshot mockDocumentSnapshot;

  // Configuração inicial antes de cada teste
  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockUser();
    mockCredential = MockUserCredential();
    mockCollectionReference = MockCollectionReference();
    mockDocumentReference = MockDocumentReference();
    mockDocumentSnapshot = MockDocumentSnapshot();

    // Setup do Comportamento Padrão do MockUser
    when(() => mockUser.uid).thenReturn(testUid);
    when(() => mockUser.email).thenReturn(testEmail);
    when(() => mockCredential.user).thenReturn(mockUser);

    // Setup do Comportamento Padrão de Firestore (para consultas de users/docs)
    when(
      () => mockFirestore.collection('users'),
    ).thenReturn(mockCollectionReference);
    when(
      () => mockCollectionReference.doc(testUid),
    ).thenReturn(mockDocumentReference);

    // Cria a instância do Repositório com os mocks injetados
    repository = AuthRepositoryImpl(auth: mockAuth, firestore: mockFirestore);
  });

  // Garante que o Mocktail está registrado para classes customizadas
  setUpAll(() {
    registerFallbackValue(UserEntity(id: 'any', email: 'any', name: 'any'));
    registerFallbackValue(StackTrace.current);
    registerFallbackValue(const Stream<User?>.empty());
  });

  group('authStateChanges', () {
    test('deve retornar o Stream<User?> do FirebaseAuth', () {
      final stream = Stream<User?>.fromIterable([mockUser, null]);
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => stream);

      expect(repository.authStateChanges, emitsInOrder([mockUser, null]));
    });
  });

  group('signUp', () {
    test('deve criar usuário e dados no Firestore com sucesso', () async {
      // 1. Setup - Mock Auth
      when(
        () => mockAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        ),
      ).thenAnswer((_) async => mockCredential);

      // 2. Setup - Mock Firestore (o método set não retorna nada)
      when(
        () => mockDocumentReference.set(any(that: isA<Map<String, dynamic>>())),
      ).thenAnswer((_) async => {});

      // 3. Act
      final result = await repository.signUp(testName, testEmail, testPassword);
      final resultEmail = result?.email;
      final resultName = result?.name;
      final resultId = result?.id;

      // 4. Assert
      expect(resultEmail, equals(expectedUserEntity.email));
      expect(resultName, equals(expectedUserEntity.name));
      expect(resultId, equals(expectedUserEntity.id));
      // Verifica se o método de Auth foi chamado
      verify(
        () => mockAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        ),
      ).called(1);
      // Verifica se o método de Firestore set foi chamado para criar o perfil
      verify(
        () => mockDocumentReference.set(any(that: hasLength(3))),
      ).called(1);
    });

    // CORREÇÃO: Estrutura do teste de exceção ajustada para ser async
    test(
      'deve relançar FirebaseAuthException em caso de falha de Auth',
      () async {
        final mockException = FirebaseAuthException(code: 'weak-password');

        // 1. Setup - Mock Auth para lançar exceção
        when(
          () => mockAuth.createUserWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
        ).thenThrow(mockException);

        // 2. Act & Assert
        await expectLater(
          repository.signUp(testName, testEmail, testPassword),
          throwsA(isA<FirebaseAuthException>()),
        );
      },
    );
  });

  group('signIn', () {
    test('deve autenticar e buscar dados do Firestore com sucesso', () async {
      // 1. Setup - Mock Auth
      when(
        () => mockAuth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        ),
      ).thenAnswer((_) async => mockCredential);

      // 2. Setup - Mock Firestore para retornar dados
      when(() => mockDocumentSnapshot.data()).thenReturn(testUserData);
      when(() => mockDocumentSnapshot.exists).thenReturn(true);
      when(
        () => mockDocumentReference.get(),
      ).thenAnswer((_) async => mockDocumentSnapshot);

      // 3. Act
      final result = await repository.signIn(testEmail, testPassword);
      final resultEmail = result?.email;
      //  final resultId = result?.id;

      // 4. Assert
      expect(resultEmail, equals(expectedUserEntity.email));
      //expect(resultId, equals(expectedUserEntity.id));
      verify(
        () => mockAuth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        ),
      ).called(1);
      verify(() => mockDocumentReference.get()).called(1);
    });

    test(
      'deve retornar null se os dados do Firestore não forem encontrados',
      () async {
        // 1. Setup - Mock Auth
        when(
          () => mockAuth.signInWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          ),
        ).thenAnswer((_) async => mockCredential);

        // 2. Setup - Mock Firestore para retornar null
        when(() => mockDocumentSnapshot.data()).thenReturn(null);
        when(() => mockDocumentSnapshot.exists).thenReturn(false);
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);

        // 3. Act
        final result = await repository.signIn(testEmail, testPassword);

        // 4. Assert
        expect(result, isNull);
      },
    );

    test('deve relançar exceção em caso de falha de login', () async {
      final mockException = FirebaseAuthException(code: 'user-not-found');

      // 1. Setup - Mock Auth para lançar exceção
      when(
        () => mockAuth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        ),
      ).thenThrow(mockException);

      // 2. Act & Assert
      await expectLater(
        repository.signIn(testEmail, testPassword),
        throwsA(isA<FirebaseAuthException>()),
      );
      // Garante que o Firestore NUNCA é chamado
      verifyNever(() => mockDocumentReference.get());
    });
  });

  group('signOut', () {
    test('deve chamar signOut do FirebaseAuth com sucesso', () async {
      // 1. Setup - Mock Auth
      when(() => mockAuth.signOut()).thenAnswer((_) async => {});

      // 2. Act
      await repository.signOut();

      // 3. Assert
      verify(() => mockAuth.signOut()).called(1);
    });

    test('deve relançar exceção em caso de falha no signOut', () async {
      final mockException = Exception('SignOut Failed');

      // 1. Setup - Mock Auth para lançar exceção
      when(() => mockAuth.signOut()).thenThrow(mockException);

      // 2. Act & Assert
      await expectLater(repository.signOut(), throwsA(isA<Exception>()));
    });
  });

  group('getCurrentUser', () {
    test(
      'deve retornar UserEntity se houver usuário e dados no Firestore',
      () async {
        // 1. Setup - Mock Auth
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        // 2. Setup - Mock Firestore
        when(() => mockDocumentSnapshot.data()).thenReturn(testUserData);
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);

        // 3. Act
        final result = await repository.getCurrentUser();
        final resultEmail = result?.email;
        final resultName = result?.name;
        final resultId = result?.id;

        // 4. Assert
        expect(resultEmail, equals(expectedUserEntity.email));
        expect(resultName, equals(expectedUserEntity.name));
        expect(resultId, equals(expectedUserEntity.id));
        verify(() => mockAuth.currentUser).called(1);
        verify(() => mockDocumentReference.get()).called(1);
      },
    );

    test(
      'deve retornar null se não houver usuário logado (currentUser é null)',
      () async {
        // 1. Setup - Mock Auth
        when(() => mockAuth.currentUser).thenReturn(null);

        // 2. Act
        final result = await repository.getCurrentUser();

        // 3. Assert
        expect(result, isNull);
        // Garante que o Firestore NUNCA é chamado
        verifyNever(() => mockDocumentReference.get());
      },
    );

    test(
      'deve retornar null se não houver dados no Firestore (data é null)',
      () async {
        // 1. Setup - Mock Auth
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        // 2. Setup - Mock Firestore para retornar null
        when(() => mockDocumentSnapshot.data()).thenReturn(null);
        when(
          () => mockDocumentReference.get(),
        ).thenAnswer((_) async => mockDocumentSnapshot);

        // 3. Act
        final result = await repository.getCurrentUser();

        // 4. Assert
        expect(result, isNull);
        verify(() => mockDocumentReference.get()).called(1);
      },
    );

    test('deve relançar exceção em caso de falha no Firestore', () async {
      final mockException = FirebaseException(
        plugin: 'Firestore',
        message: 'Network Error',
      );

      // 1. Setup - Mock Auth
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      // 2. Setup - Mock Firestore para lançar exceção
      when(() => mockDocumentReference.get()).thenThrow(mockException);

      // 3. Act & Assert
      await expectLater(
        repository.getCurrentUser(),
        throwsA(isA<FirebaseException>()),
      );
      verify(() => mockAuth.currentUser).called(1);
    });
  });
}
