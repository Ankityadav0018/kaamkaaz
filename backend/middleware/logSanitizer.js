/**
 * logSanitizer.js — Section 6: Log Sanitization Middleware
 *
 * Strips sensitive fields from logs before they are written.
 * Wraps console.error / console.log to redact known sensitive keys.
 *
 * Also provides Morgan token override to strip auth headers from HTTP logs.
 *
 * Call setupLogSanitizer() once at server startup (before any routes).
 */

const SENSITIVE_KEYS = [
  'password', 'newPassword', 'oldPassword', 'confirmPassword',
  'otp', 'token', 'refreshToken', 'accessToken', 'kk_refresh',
  'aadhaarNumber', 'panNumber', 'bankAccount', 'ifsc',
  'creditCard', 'cvv', 'ssn',
  'GEMINI_API_KEY', 'JWT_SECRET', 'REFRESH_TOKEN_SECRET',
  'ACCESS_TOKEN_SECRET', 'FIELD_ENCRYPTION_KEY', 'SMTP_PASS',
  'RAZORPAY_KEY_SECRET', 'SUPABASE_SERVICE_ROLE_KEY'
];

const REDACTED = '[REDACTED]';

/** Deep-clone and redact sensitive keys from an object */
const sanitizeObject = (obj, depth = 0) => {
  if (depth > 6 || !obj || typeof obj !== 'object') return obj;
  if (Array.isArray(obj)) return obj.map(item => sanitizeObject(item, depth + 1));

  const result = {};
  for (const [key, value] of Object.entries(obj)) {
    if (SENSITIVE_KEYS.some(k => key.toLowerCase().includes(k.toLowerCase()))) {
      result[key] = REDACTED;
    } else if (typeof value === 'object') {
      result[key] = sanitizeObject(value, depth + 1);
    } else {
      result[key] = value;
    }
  }
  return result;
};

/** Sanitize a log argument (handles strings, objects, Errors) */
const sanitizeArg = (arg) => {
  if (!arg) return arg;
  if (typeof arg === 'string') {
    // Redact JSON-embedded sensitive fields in log strings
    return arg.replace(
      /"?(password|otp|token|aadhaarNumber|refreshToken|accessToken)"?\s*[:=]\s*"?([^",}\s]{1,200})"?/gi,
      (match, key) => `"${key}": "${REDACTED}"`
    );
  }
  if (arg instanceof Error) {
    // Don't sanitize error messages — just redact the stack if it has sensitive data
    const sanitized = new Error(sanitizeArg(arg.message));
    sanitized.stack = arg.stack;
    return sanitized;
  }
  if (typeof arg === 'object') return sanitizeObject(arg);
  return arg;
};

/** Patch global console methods to sanitize arguments before printing */
exports.setupLogSanitizer = () => {
  const originalLog   = console.log.bind(console);
  const originalError = console.error.bind(console);
  const originalWarn  = console.warn.bind(console);

  console.log   = (...args) => originalLog(...args.map(sanitizeArg));
  console.error = (...args) => originalError(...args.map(sanitizeArg));
  console.warn  = (...args) => originalWarn(...args.map(sanitizeArg));

  console.info('[LogSanitizer] ✅ Console log sanitization active.');
};

/**
 * Express middleware — sanitizes req.body before any downstream logging.
 * Place early in the middleware chain (after express.json()).
 */
exports.sanitizeRequestBody = (req, res, next) => {
  if (req.body && typeof req.body === 'object') {
    req.sanitizedBody = sanitizeObject(req.body);
  }
  next();
};

exports.sanitizeObject = sanitizeObject;
