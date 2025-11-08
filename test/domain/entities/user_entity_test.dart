// test/domain/entities/user_entity_test.dart
import 'package:auth/auth/domain/entities/user_entity.dart';
import 'package:flutter_test/flutter_test.dart';


// Início dos Testes


void main() {
  // Constantes de dados para facilitar a leitura dos testes
  const String baseId = 'user_id_123';
  const String baseEmail = 'user@example.com';
  const String baseName = 'John Doe';

  group('UserEntity', () {
    // -----------------------------------------------------
    // Testes de Instanciação e Getters
    // -----------------------------------------------------

    test('deve criar uma instância corretamente com nome não nulo', () {
      final user = UserEntity(id: baseId, email: baseEmail, name: baseName);
      
      expect(user.id, baseId);
      expect(user.email, baseEmail);
      expect(user.name, baseName);
      expect(user.uid, baseId); // Verifica o getter 'uid'
    });

    test('deve criar uma instância corretamente com nome nulo', () {
      final user = UserEntity(id: baseId, email: baseEmail, name: null);
      
      expect(user.id, baseId);
      expect(user.email, baseEmail);
      expect(user.name, isNull);
    });

    // -----------------------------------------------------
    // Testes de Igualdade (==) e Hash Code
    // -----------------------------------------------------

    test('dois objetos com os mesmos valores devem ser considerados iguais', () {
      final user1 = UserEntity(id: baseId, email: baseEmail, name: baseName);
      final user2 = UserEntity(id: baseId, email: baseEmail, name: baseName);
      
      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
    });

    test('dois objetos com nome nulo devem ser considerados iguais', () {
      final user1 = UserEntity(id: baseId, email: baseEmail, name: null);
      final user2 = UserEntity(id: baseId, email: baseEmail, name: null);
      
      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
    });

    test('objetos com IDs diferentes não devem ser iguais', () {
      final user1 = UserEntity(id: baseId, email: baseEmail, name: baseName);
      final user2 = UserEntity(id: 'different_id', email: baseEmail, name: baseName);
      
      expect(user1, isNot(equals(user2)));
      expect(user1.hashCode, isNot(equals(user2.hashCode)));
    });
    
    test('objetos com nomes diferentes não devem ser iguais', () {
      final user1 = UserEntity(id: baseId, email: baseEmail, name: baseName);
      final user2 = UserEntity(id: baseId, email: baseEmail, name: 'Jane Doe');
      
      expect(user1, isNot(equals(user2)));
      // Hash codes podem ser iguais por colisão, mas a igualdade deve falhar
      expect(user1.hashCode, isNot(equals(user2.hashCode))); 
    });

    test('objeto com nome nulo não deve ser igual a objeto com nome não nulo', () {
      final userWithName = UserEntity(id: baseId, email: baseEmail, name: baseName);
      final userWithoutName = UserEntity(id: baseId, email: baseEmail, name: null);
      
      expect(userWithName, isNot(equals(userWithoutName)));
    });

    // -----------------------------------------------------
    // Testes de copyWith
    // -----------------------------------------------------
    
    test('copyWith sem argumentos deve retornar um novo objeto idêntico', () {
      final original = UserEntity(id: baseId, email: baseEmail, name: baseName);
      final copied = original.copyWith();
      
      // Deve ser um objeto diferente na memória
      expect(copied, isNot(same(original)));
      // Deve ser igual em valor
      expect(copied, equals(original)); 
    });

    test('copyWith deve atualizar apenas o ID', () {
      final original = UserEntity(id: baseId, email: baseEmail, name: baseName);
      const newId = 'new_id_456';
      final updated = original.copyWith(id: newId);

      expect(updated.id, newId);
      expect(updated.email, original.email);
      expect(updated.name, original.name);
      expect(updated, isNot(equals(original)));
    });

    test('copyWith deve atualizar apenas o email', () {
      final original = UserEntity(id: baseId, email: baseEmail, name: baseName);
      const newEmail = 'new@example.com';
      final updated = original.copyWith(email: newEmail);

      expect(updated.id, original.id);
      expect(updated.email, newEmail);
      expect(updated.name, original.name);
      expect(updated, isNot(equals(original)));
    });

    test('copyWith deve atualizar apenas o nome', () {
      final original = UserEntity(id: baseId, email: baseEmail, name: baseName);
      const newName = 'Mary Jane';
      final updated = original.copyWith(name: newName);

      expect(updated.id, original.id);
      expect(updated.email, original.email);
      expect(updated.name, newName);
      expect(updated, isNot(equals(original)));
    });


  });
}
