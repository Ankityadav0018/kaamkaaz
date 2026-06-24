import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  static const _storage = FlutterSecureStorage();
  static const _pinKey = 'app_lock_pin_hash';
  static const _salt = 'kaamkaaz_salt_xyz';

  static Future<void> setPin(String pin) async {
    if (pin.length != 6) throw ArgumentError('PIN must be 6 digits');
    final hash = _hashPin(pin);
    await _storage.write(key: _pinKey, value: hash);
  }

  static Future<bool> verifyPin(String pin) async {
    final savedHash = await _storage.read(key: _pinKey);
    if (savedHash == null) return false;
    return _hashPin(pin) == savedHash;
  }

  static Future<bool> hasPin() async {
    final hash = await _storage.read(key: _pinKey);
    return hash != null && hash.isNotEmpty;
  }

  static Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
  }

  static String _hashPin(String pin) {
    final bytes = utf8.encode(_salt + pin);
    return sha256.convert(bytes).toString();
  }
}
