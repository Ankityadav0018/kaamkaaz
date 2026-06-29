/**
 * encryption.js — Section 3, 4, 6: AES-256-GCM Field Encryption
 *
 * Encrypts sensitive fields at rest (Aadhaar numbers, etc.).
 * Stores { ciphertext, iv, tag } as a JSON string in MongoDB.
 *
 * Key must be exactly 32 bytes (64 hex chars).
 * Generate with: openssl rand -hex 32
 *
 * Usage:
 *   const { encrypt, decrypt, isEncrypted } = require('../utils/encryption');
 *   user.aadhaarNumber = encrypt('123456789012');
 *   const plain = decrypt(user.aadhaarNumber);
 */

const crypto = require('crypto');

const ALGORITHM  = 'aes-256-gcm';
const KEY_HEX    = process.env.FIELD_ENCRYPTION_KEY || '';

/**
 * Get the encryption key buffer.
 * Falls back to a zero-key in development if not configured (logs a warning).
 */
const getKey = () => {
  if (KEY_HEX.length === 64) {
    return Buffer.from(KEY_HEX, 'hex');
  }
  if (process.env.NODE_ENV !== 'production') {
    // Development-only fallback — warns on every call
    if (!getKey._warned) {
      console.warn('[Encryption] WARNING: FIELD_ENCRYPTION_KEY not set. Using insecure dev key. Set this in production!');
      getKey._warned = true;
    }
    return Buffer.alloc(32, 0); // zero key — NOT for production
  }
  throw new Error('FIELD_ENCRYPTION_KEY must be a 64-character hex string (32 bytes). Generate with: openssl rand -hex 32');
};

/** Encrypt a plaintext string. Returns a JSON string storing ciphertext, iv, tag. */
exports.encrypt = (plaintext) => {
  if (!plaintext) return plaintext;
  // Already encrypted — don't double-encrypt
  if (exports.isEncrypted(plaintext)) return plaintext;

  const key    = getKey();
  const iv     = crypto.randomBytes(12); // 96-bit IV for GCM
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);

  const encrypted = Buffer.concat([
    cipher.update(String(plaintext), 'utf8'),
    cipher.final()
  ]);
  const tag = cipher.getAuthTag();

  return JSON.stringify({
    v:          1, // version for future algorithm changes
    ciphertext: encrypted.toString('base64'),
    iv:         iv.toString('base64'),
    tag:        tag.toString('base64')
  });
};

/** Decrypt an encrypted field string. Returns the original plaintext. */
exports.decrypt = (encryptedJson) => {
  if (!encryptedJson) return encryptedJson;
  if (!exports.isEncrypted(encryptedJson)) return encryptedJson; // not encrypted — return as-is

  try {
    const { ciphertext, iv, tag } = JSON.parse(encryptedJson);
    const key      = getKey();
    const decipher = crypto.createDecipheriv(ALGORITHM, key, Buffer.from(iv, 'base64'));
    decipher.setAuthTag(Buffer.from(tag, 'base64'));

    return Buffer.concat([
      decipher.update(Buffer.from(ciphertext, 'base64')),
      decipher.final()
    ]).toString('utf8');
  } catch (err) {
    console.error('[Encryption] Decryption failed:', err.message);
    return null; // safe fallback
  }
};

/**
 * Check if a string is an encrypted blob (safe to call on any value).
 */
exports.isEncrypted = (value) => {
  if (!value || typeof value !== 'string') return false;
  try {
    const parsed = JSON.parse(value);
    return parsed?.v === 1 && parsed?.ciphertext && parsed?.iv && parsed?.tag;
  } catch {
    return false;
  }
};

/**
 * Mask a decrypted value for safe display (e.g. Aadhaar: XXXXXXXX1234).
 */
exports.maskAadhaar = (value) => {
  if (!value) return null;
  const plain = exports.isEncrypted(value) ? exports.decrypt(value) : value;
  if (!plain || plain.length < 4) return '****';
  return 'XXXXXXXX' + plain.slice(-4);
};
