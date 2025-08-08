# Security Best Practices for Spiral Journal Development

## Overview

This document provides security guidelines and best practices for developers working on the Spiral Journal Flutter application. Following these practices will help maintain the security and privacy of user data.

## 1. API Key Management

### Never Do This
```dart
// BAD: Hardcoded API key
const String apiKey = "sk-ant-api03-...";

// BAD: API key in repository
// .env file with actual keys committed

// BAD: Logging API keys
debugPrint('API Key: $apiKey');
```

### Do This Instead
```dart
// GOOD: Load from secure storage
final apiKey = await secureStorage.read(key: 'api_key');

// GOOD: Use environment variables at build time
const String apiKey = String.fromEnvironment('API_KEY');

// GOOD: Log only validation status
debugPrint('API Key valid: ${apiKey != null}');
```

### Best Practices
1. Use server-side proxy for API calls when possible
2. Rotate API keys regularly
3. Use different keys for development and production
4. Never commit `.env` files with real keys
5. Use `.env.example` with placeholder values

## 2. Password and Authentication

### Never Do This
```dart
// BAD: Weak hashing
final hash = sha256.convert(utf8.encode(password));

// BAD: No password requirements
if (password.isNotEmpty) { /* accept */ }

// BAD: Storing plaintext
prefs.setString('password', password);
```

### Do This Instead
```dart
// GOOD: Strong hashing with salt
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

String hashPassword(String password) {
  final salt = Uuid().v4();
  final bytes = utf8.encode('$password$salt');
  final hash = sha256.convert(bytes);
  return '$salt:${hash.toString()}';
}

// GOOD: Password requirements
bool isValidPassword(String password) {
  return password.length >= 8 &&
         password.contains(RegExp(r'[A-Z]')) &&
         password.contains(RegExp(r'[a-z]')) &&
         password.contains(RegExp(r'[0-9]'));
}

// GOOD: Secure storage
await secureStorage.write(key: 'password_hash', value: hashedPassword);
```

## 3. Input Validation and Sanitization

### Never Do This
```dart
// BAD: No validation
final entry = JournalEntry(content: userInput);

// BAD: Direct SQL with user input
db.rawQuery('SELECT * FROM entries WHERE content = "$userInput"');

// BAD: No length limits
TextFormField(maxLength: null);
```

### Do This Instead
```dart
// GOOD: Input validation
String sanitizeInput(String input) {
  // Remove dangerous characters
  final sanitized = input
    .replaceAll(RegExp(r'<script.*?>.*?</script>', caseSensitive: false), '')
    .replaceAll(RegExp(r'<.*?>'), '')
    .trim();
  
  // Enforce length limit
  return sanitized.length > 10000 
    ? sanitized.substring(0, 10000) 
    : sanitized;
}

// GOOD: Parameterized queries
db.query(
  'entries',
  where: 'content = ?',
  whereArgs: [sanitizeInput(userInput)],
);

// GOOD: Input constraints
TextFormField(
  maxLength: 5000,
  inputFormatters: [
    FilteringTextInputFormatter.deny(RegExp(r'<[^>]*>')),
  ],
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter some text';
    }
    if (value.length < 10) {
      return 'Entry too short';
    }
    return null;
  },
);
```

## 4. Secure Data Storage

### Never Do This
```dart
// BAD: Unencrypted sensitive data
final file = File('journal.txt');
await file.writeAsString(journalContent);

// BAD: Sensitive data in SharedPreferences
prefs.setString('api_key', apiKey);

// BAD: No encryption for exports
final json = jsonEncode(entries);
await shareFile(json);
```

### Do This Instead
```dart
// GOOD: Encrypted file storage
import 'package:encrypt/encrypt.dart';

Future<void> saveEncrypted(String content) async {
  final key = Key.fromSecureRandom(32);
  final iv = IV.fromSecureRandom(16);
  final encrypter = Encrypter(AES(key));
  
  final encrypted = encrypter.encrypt(content, iv: iv);
  await secureStorage.write(key: 'content', value: encrypted.base64);
}

// GOOD: Secure storage for sensitive data
await secureStorage.write(key: 'api_key', value: apiKey);

// GOOD: Encrypted exports
Future<String> exportEncrypted(List<JournalEntry> entries) async {
  final jsonString = jsonEncode(entries);
  final encrypted = await encryptContent(jsonString);
  return encrypted;
}
```

## 5. Network Security

### Never Do This
```dart
// BAD: HTTP instead of HTTPS
final response = await http.get(Uri.parse('http://api.example.com'));

// BAD: No timeout
final response = await http.get(uri);

// BAD: No error handling
final data = jsonDecode(response.body);
```

### Do This Instead
```dart
// GOOD: HTTPS with certificate pinning
import 'dart:io';

Future<HttpClient> createHttpClient() async {
  final context = SecurityContext();
  // Add certificate for pinning
  context.setTrustedCertificatesBytes(certificateBytes);
  
  return HttpClient(context: context);
}

// GOOD: Timeout and retry
Future<Response> secureRequest(Uri uri) async {
  const timeout = Duration(seconds: 30);
  const maxRetries = 3;
  
  for (int i = 0; i < maxRetries; i++) {
    try {
      final response = await http
          .get(uri)
          .timeout(timeout);
          
      if (response.statusCode == 200) {
        return response;
      }
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(Duration(seconds: i + 1));
    }
  }
  throw Exception('Request failed after $maxRetries attempts');
}

// GOOD: Safe error handling
try {
  final response = await secureRequest(uri);
  final data = jsonDecode(response.body);
  return data;
} catch (e) {
  // Don't expose internal errors
  throw Exception('Network request failed');
}
```

## 6. Logging and Error Handling

### Never Do This
```dart
// BAD: Logging sensitive data
debugPrint('User password: $password');
debugPrint('API response: ${response.body}');

// BAD: Exposing stack traces
catch (e, stack) {
  return 'Error: $e\nStack: $stack';
}
```

### Do This Instead
```dart
// GOOD: Sanitized logging
class SecureLogger {
  static void log(String message, {Map<String, dynamic>? data}) {
    final sanitized = _sanitizeData(data);
    debugPrint('[$message] ${sanitized.toString()}');
  }
  
  static Map<String, dynamic> _sanitizeData(Map<String, dynamic>? data) {
    if (data == null) return {};
    
    return data.map((key, value) {
      if (_isSensitiveKey(key)) {
        return MapEntry(key, '***REDACTED***');
      }
      return MapEntry(key, value);
    });
  }
  
  static bool _isSensitiveKey(String key) {
    final sensitive = ['password', 'apiKey', 'token', 'secret'];
    return sensitive.any((s) => key.toLowerCase().contains(s));
  }
}

// GOOD: Safe error messages
catch (e) {
  SecureLogger.log('Operation failed', data: {'type': e.runtimeType.toString()});
  return 'An error occurred. Please try again.';
}
```

## 7. Code Security Practices

### General Guidelines

1. **Principle of Least Privilege**: Only request permissions that are absolutely necessary
2. **Defense in Depth**: Implement multiple layers of security
3. **Fail Securely**: Ensure the application fails to a secure state
4. **Regular Updates**: Keep all dependencies up to date

### Security Checklist for New Features

- [ ] All user inputs are validated and sanitized
- [ ] Sensitive data is encrypted at rest and in transit  
- [ ] API calls use HTTPS with proper certificates
- [ ] Error messages don't expose sensitive information
- [ ] Authentication is required for sensitive operations
- [ ] Logs don't contain sensitive data
- [ ] Security headers are properly configured
- [ ] Rate limiting is implemented where appropriate

### Code Review Security Checklist

- [ ] No hardcoded secrets or credentials
- [ ] No sensitive data in logs or error messages
- [ ] Input validation is comprehensive
- [ ] SQL queries use parameter binding
- [ ] File operations validate paths
- [ ] Network requests have timeouts
- [ ] Error handling doesn't expose internals
- [ ] Authentication checks can't be bypassed

## 8. Testing Security

### Security Test Cases

```dart
// Test input validation
test('should reject malicious input', () {
  final maliciousInputs = [
    '<script>alert("xss")</script>',
    'SELECT * FROM users',
    '../../../etc/passwd',
    'A' * 100000, // Very long input
  ];
  
  for (final input in maliciousInputs) {
    expect(
      () => validateJournalContent(input),
      throwsA(isA<ValidationException>()),
    );
  }
});

// Test authentication
test('should prevent access without authentication', () async {
  final service = JournalService();
  
  // Ensure no auth token
  await secureStorage.deleteAll();
  
  expect(
    () => service.getEntries(),
    throwsA(isA<UnauthorizedException>()),
  );
});

// Test encryption
test('should encrypt sensitive data', () async {
  final plaintext = 'Sensitive journal entry';
  final encrypted = await encryptContent(plaintext);
  
  expect(encrypted, isNot(contains(plaintext)));
  expect(encrypted.length, greaterThan(plaintext.length));
});
```

## 9. Incident Response

### If a Security Issue is Discovered

1. **Don't Panic**: Take time to understand the issue
2. **Document**: Write down what you've found
3. **Don't Commit**: Don't commit fixes that might expose the issue
4. **Notify**: Inform the security team immediately
5. **Fix Carefully**: Ensure the fix doesn't introduce new issues
6. **Test Thoroughly**: Verify the fix works and doesn't break functionality
7. **Document**: Update security documentation

### Security Contacts

- Security Team: security@spiraljournal.app
- Bug Bounty: bugbounty@spiraljournal.app

## 10. Resources

### Tools
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [Crypto Package](https://pub.dev/packages/crypto)
- [Encrypt Package](https://pub.dev/packages/encrypt)

### References
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Flutter Security Best Practices](https://flutter.dev/docs/development/security)
- [NIST Cryptographic Standards](https://www.nist.gov/cryptography)

Remember: Security is everyone's responsibility. When in doubt, ask for help!