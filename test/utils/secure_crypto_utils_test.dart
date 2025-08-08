import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/utils/secure_crypto_utils.dart';

void main() {
  group('SecureCryptoUtils', () {
    group('Password Validation', () {
      test('should accept strong passwords', () {
        final strongPasswords = [
          'MyStr0ng!P@ssw0rd123',
          'C0mpl3x#SecurE\$Pass2024',
          'Th1s!Is@V3ry\$Strong%Password^2024',
        ];

        for (final password in strongPasswords) {
          final result = SecureCryptoUtils.validatePassword(password);
          expect(result.isValid, isTrue, reason: 'Password: $password should be valid');
          expect(result.strength, greaterThanOrEqualTo(60));
        }
      });

      test('should reject weak passwords', () {
        final weakPasswords = [
          'password',           // Common weak pattern
          '123456789',         // Only numbers
          'abcdefgh',          // Only lowercase
          'ABCDEFGH',          // Only uppercase
          'short',             // Too short
          'nospecialchars123', // No special characters
          'aaa111!!!',         // Repeated characters
        ];

        for (final password in weakPasswords) {
          final result = SecureCryptoUtils.validatePassword(password);
          expect(result.isValid, isFalse, reason: 'Password: $password should be invalid');
          expect(result.issues, isNotEmpty);
        }
      });

      test('should provide helpful validation messages', () {
        final result = SecureCryptoUtils.validatePassword('weak');
        
        expect(result.issues, contains(contains('12 characters')));
        expect(result.issues, contains(contains('uppercase')));
        expect(result.issues, contains(contains('numbers')));
        expect(result.issues, contains(contains('special characters')));
      });

      test('should calculate password strength correctly', () {
        final testCases = <Map<String, dynamic>>[
          {'password': 'MyStr0ng!P@ssw0rd123', 'expectedStrength': 80}, // Very strong
          {'password': 'C0mpl3x#Pass', 'expectedStrength': 70},         // Strong  
          {'password': 'Simple123!', 'expectedStrength': 60},           // Moderate
          {'password': 'weak123', 'expectedStrength': 30},              // Weak
        ];

        for (final testCase in testCases) {
          final password = testCase['password'] as String;
          final expectedStrength = testCase['expectedStrength'] as int;
          final result = SecureCryptoUtils.validatePassword(password);
          expect(result.strength, greaterThanOrEqualTo(expectedStrength - 10));
          expect(result.strength, lessThanOrEqualTo(expectedStrength + 10));
        }
      });
    });

    group('Cryptographic Functions', () {
      test('should generate secure random bytes', () {
        final bytes1 = SecureCryptoUtils.generateSecureRandomBytes(32);
        final bytes2 = SecureCryptoUtils.generateSecureRandomBytes(32);
        
        expect(bytes1.length, equals(32));
        expect(bytes2.length, equals(32));
        expect(bytes1, isNot(equals(bytes2))); // Should be random
      });

      test('should derive keys consistently', () {
        const password = 'MyTestPassword123!';
        final salt = SecureCryptoUtils.generateSecureRandomBytes(16);
        
        final key1 = SecureCryptoUtils.deriveKey(password, salt);
        final key2 = SecureCryptoUtils.deriveKey(password, salt);
        
        expect(key1, equals(key2)); // Same password + salt = same key
        expect(key1.length, equals(32)); // 256 bits
      });

      test('should derive different keys for different salts', () {
        const password = 'MyTestPassword123!';
        final salt1 = SecureCryptoUtils.generateSecureRandomBytes(16);
        final salt2 = SecureCryptoUtils.generateSecureRandomBytes(16);
        
        final key1 = SecureCryptoUtils.deriveKey(password, salt1);
        final key2 = SecureCryptoUtils.deriveKey(password, salt2);
        
        expect(key1, isNot(equals(key2))); // Different salts = different keys
      });
    });

    group('Encryption/Decryption', () {
      test('should encrypt and decrypt data correctly', () {
        const testData = 'This is sensitive test data that needs encryption!';
        const password = 'MyStr0ng!P@ssw0rd123';
        
        final encryptionResult = SecureCryptoUtils.encryptData(testData, password);
        final decryptedData = SecureCryptoUtils.decryptData(encryptionResult, password);
        
        expect(decryptedData, equals(testData));
        expect(encryptionResult.version, equals('2.0'));
        expect(encryptionResult.iterations, equals(100000));
      });

      test('should fail decryption with wrong password', () {
        const testData = 'Secret data';
        const correctPassword = 'MyStr0ng!P@ssw0rd123';
        const wrongPassword = 'Wr0ng!P@ssw0rd456';
        
        final encryptionResult = SecureCryptoUtils.encryptData(testData, correctPassword);
        
        expect(
          () => SecureCryptoUtils.decryptData(encryptionResult, wrongPassword),
          throwsException,
        );
      });

      test('should reject weak passwords for encryption', () {
        const testData = 'Secret data';
        const weakPassword = 'weak';
        
        expect(
          () => SecureCryptoUtils.encryptData(testData, weakPassword),
          throwsArgumentError,
        );
      });

      test('should handle JSON serialization correctly', () {
        const testData = 'Test data for JSON serialization';
        const password = 'MyStr0ng!P@ssw0rd123';
        
        final encryptionResult = SecureCryptoUtils.encryptData(testData, password);
        final json = encryptionResult.toJson();
        final reconstructed = EncryptionResult.fromJson(json);
        
        final decryptedData = SecureCryptoUtils.decryptData(reconstructed, password);
        expect(decryptedData, equals(testData));
      });

      test('should handle large data correctly', () {
        final largeData = 'A' * 100000; // 100KB of data
        const password = 'MyStr0ng!P@ssw0rd123';
        
        final encryptionResult = SecureCryptoUtils.encryptData(largeData, password);
        final decryptedData = SecureCryptoUtils.decryptData(encryptionResult, password);
        
        expect(decryptedData, equals(largeData));
        expect(decryptedData.length, equals(100000));
      });

      test('should handle unicode data correctly', () {
        const unicodeData = 'こんにちは世界! 🌍 émojis & spéciål chârs';
        const password = 'MyStr0ng!P@ssw0rd123';
        
        final encryptionResult = SecureCryptoUtils.encryptData(unicodeData, password);
        final decryptedData = SecureCryptoUtils.decryptData(encryptionResult, password);
        
        expect(decryptedData, equals(unicodeData));
      });
    });

    group('Security Features', () {
      test('should use different IVs for same data', () {
        const testData = 'Same data, different encryption';
        const password = 'MyStr0ng!P@ssw0rd123';
        
        final result1 = SecureCryptoUtils.encryptData(testData, password);
        final result2 = SecureCryptoUtils.encryptData(testData, password);
        
        expect(result1.iv, isNot(equals(result2.iv)));
        expect(result1.encryptedData, isNot(equals(result2.encryptedData)));
        
        // But both should decrypt to the same original data
        final decrypted1 = SecureCryptoUtils.decryptData(result1, password);
        final decrypted2 = SecureCryptoUtils.decryptData(result2, password);
        expect(decrypted1, equals(testData));
        expect(decrypted2, equals(testData));
      });

      test('should perform constant-time string comparison', () {
        const string1 = 'identical';
        const string2 = 'identical';
        const string3 = 'different';
        
        expect(SecureCryptoUtils.constantTimeEquals(string1, string2), isTrue);
        expect(SecureCryptoUtils.constantTimeEquals(string1, string3), isFalse);
        expect(SecureCryptoUtils.constantTimeEquals('', ''), isTrue);
        expect(SecureCryptoUtils.constantTimeEquals('a', ''), isFalse);
      });

      test('should handle edge cases gracefully', () {
        const password = 'MyStr0ng!P@ssw0rd123';
        
        // Empty data
        final emptyResult = SecureCryptoUtils.encryptData('', password);
        final emptyDecrypted = SecureCryptoUtils.decryptData(emptyResult, password);
        expect(emptyDecrypted, equals(''));
        
        // Single character
        final singleResult = SecureCryptoUtils.encryptData('x', password);
        final singleDecrypted = SecureCryptoUtils.decryptData(singleResult, password);
        expect(singleDecrypted, equals('x'));
      });
    });

    group('Performance', () {
      test('should complete encryption/decryption within reasonable time', () {
        const testData = 'Performance test data';
        const password = 'MyStr0ng!P@ssw0rd123';
        
        final stopwatch = Stopwatch()..start();
        
        final encryptionResult = SecureCryptoUtils.encryptData(testData, password);
        final encryptionTime = stopwatch.elapsedMilliseconds;
        
        stopwatch.reset();
        final decryptedData = SecureCryptoUtils.decryptData(encryptionResult, password);
        final decryptionTime = stopwatch.elapsedMilliseconds;
        
        stopwatch.stop();
        
        expect(decryptedData, equals(testData));
        expect(encryptionTime, lessThan(5000)); // Less than 5 seconds
        expect(decryptionTime, lessThan(5000)); // Less than 5 seconds
        
        print('Encryption time: ${encryptionTime}ms');
        print('Decryption time: ${decryptionTime}ms');
      });
    });
  });
}