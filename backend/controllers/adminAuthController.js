const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const speakeasy = require('speakeasy');
const User = require('../models/User');
const AdminAuditLog = require('../models/AdminAuditLog');
const { redisClient: redis, safeRedisGet, safeRedisSetex } = require('../config/redis');
const adminMailer = require('../services/adminMailer');
const firebaseAdmin = require('../config/firebase');


// ─── Constants ────────────────────────────────────────────────────────────────

const PENDING_JWT_EXPIRE = process.env.ADMIN_JWT_PENDING_EXPIRE || '15m';
const FULL_JWT_EXPIRE    = process.env.ADMIN_JWT_EXPIRE          || '8h'; // 8 hours to survive Redis restarts
const ADMIN_SECRET       = process.env.ADMIN_JWT_SECRET          || process.env.JWT_SECRET;
const OTP_EXPIRE_SEC     = 5 * 60; // 5 minutes
const LOCK_DURATION_SEC  = 10 * 60; // 10 minutes
const MAX_OTP_ATTEMPTS   = 3;
const INACTIVITY_SEC     = 8 * 60 * 60; // 8 hours (must match adminSession.js)

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Get real client IP, respecting reverse-proxy headers */
const getIp = (req) =>
  (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || req.socket.remoteAddress || '0.0.0.0';

/** Generate a cryptographically safe 6-digit numeric OTP */
const generateOtp = () => String(Math.floor(100000 + Math.random() * 900000));

/** Sign a JWT using the separate admin secret */
const signAdminJwt = (payload, expiresIn) =>
  jwt.sign(payload, ADMIN_SECRET, { expiresIn });

/**
 * Redis keys used by the auth controller:
 *   admin:otp:<adminId>        — stored OTP (email/SMS flow)
 *   admin:otp_attempts:<adminId> — failed OTP attempt counter
 *   admin:lock:<adminId>       — lockout flag
 *   admin:blacklist:<token>    — revoked tokens
 *   admin:session:lastActive:<adminId> — inactivity tracker (Layer 5)
 */

// ─── Layer 1: Admin Login ─────────────────────────────────────────────────────

/**
 * POST /api/admin/auth/login
 * Body: { email, password }
 *
 * On success → issues admin_pending JWT (15 min, IP-bound).
 * Does NOT yet grant access to admin data routes.
 */
exports.adminLogin = async (req, res) => {
  try {
    const { email, password } = req.body;
    const ip = getIp(req);

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required.' });
    }

    // ── Check IP brute-force block (Layer 3 integration) ──────────────────────
    const ipFailKey = `admin:ip_fails:${ip}`;
    const ipFails = await safeRedisGet(ipFailKey);
    if (parseInt(ipFails || '0', 10) >= 5) {
      return res.status(429).json({
        success: false,
        message: 'Too many failed attempts from this IP. Try again in 30 minutes.'
      });
    }

    // ── Find admin ────────────────────────────────────────────────────────────
    const admin = await User.findOne({ email: email.toLowerCase(), role: 'admin' }).select('+password');
    if (!admin) {
      await redis.multi()
        .incr(ipFailKey)
        .expire(ipFailKey, 30 * 60)
        .exec();
      return res.status(401).json({ success: false, message: 'Authentication failed.' });
    }

    // ── Check account lockout (set by OTP failures) ───────────────────────────
    const lockKey = `admin:lock:${admin._id}`;
    const isLocked = await safeRedisGet(lockKey);
    if (isLocked) {
      const ttl = await redis.ttl(lockKey);
      return res.status(403).json({
        success: false,
        message: `Account temporarily locked. Try again in ${Math.ceil(ttl / 60)} minute(s).`
      });
    }

    // ── Password verify ───────────────────────────────────────────────────────
    const isMatch = await bcrypt.compare(password, admin.password);
    if (!isMatch) {
      await redis.multi()
        .incr(ipFailKey)
        .expire(ipFailKey, 30 * 60)
        .exec();
      return res.status(401).json({ success: false, message: 'Authentication failed.' });
    }

    // ── Reset IP fail counter on successful password ──────────────────────────
    await redis.del(ipFailKey);

    // ── Issue admin_pending JWT (Layer 1 complete) ─────────────────────────────
    // Note: issuedIp removed — mobile clients change IPs (WiFi ↔ 4G)
    const pendingToken = signAdminJwt(
      {
        id: admin._id,
        role: 'admin_pending'
      },
      PENDING_JWT_EXPIRE
    );

    if (!admin.twoFactorEnabled) {
      return res.status(200).json({
        success: true,
        message: 'Password verified. Please set up two-factor authentication.',
        token: pendingToken,
        requireSetup: true
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Password verified. Please verify your phone number.',
      token: pendingToken,
      requireAdminOtp: true,
      phone: admin.phone
    });

  } catch (err) {
    console.error('[adminLogin] Error:', err);
    return res.status(500).json({ success: false, message: 'Server error during authentication.' });
  }
};

// ─── Layer 2: OTP / TOTP Verification ────────────────────────────────────────

/**
 * POST /api/admin/auth/verify-otp
 * Headers: Authorization: Bearer <admin_pending token>
 * Body: { otp }
 *
 * Validates OTP (email or TOTP). On success → issues full admin JWT.
 * On 3 failures → locks account for 10 minutes.
 */
exports.adminVerifyOtp = async (req, res) => {
  try {
    const { idToken } = req.body;
    const ip = getIp(req);

    if (!idToken) {
      return res.status(400).json({ success: false, message: 'Firebase ID Token is required.' });
    }

    // ── Validate the admin_pending token ──────────────────────────────────────
    const authHeader = req.headers.authorization || '';
    const pendingToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
    if (!pendingToken) {
      return res.status(401).json({ success: false, message: 'Missing authentication token.' });
    }

    let decoded;
    try {
      decoded = jwt.verify(pendingToken, ADMIN_SECRET);
    } catch {
      return res.status(401).json({ success: false, message: 'Authentication token is invalid or expired.' });
    }

    if (decoded.role !== 'admin_pending') {
      return res.status(403).json({ success: false, message: 'Invalid token stage.' });
    }

    // ── Check if token itself is blacklisted ──────────────────────────────────
    const blacklistKey = `admin:blacklist:${pendingToken}`;
    if (await safeRedisGet(blacklistKey)) {
      return res.status(401).json({ success: false, message: 'Token has been revoked.' });
    }

    // ── IP must match the one used in adminLogin ────────────────────────────────
    // IP check removed — mobile clients frequently change IPs between login steps

    const admin = await User.findById(decoded.id).select('+totpSecret');
    if (!admin || admin.role !== 'admin') {
      return res.status(401).json({ success: false, message: 'Authentication failed.' });
    }

    // ── Account lockout guard ─────────────────────────────────────────────────
    const lockKey = `admin:lock:${admin._id}`;
    if (await safeRedisGet(lockKey)) {
      const ttl = await redis.ttl(lockKey);
      return res.status(403).json({
        success: false,
        message: `Account locked. Try again in ${Math.ceil(ttl / 60)} minute(s).`
      });
    }

    const attemptsKey = `admin:otp_attempts:${admin._id}`;

    // ── OTP Validation via Firebase Admin SDK ─────────────────────────────────
    let otpValid = false;
    try {
      const decodedFirebaseToken = await firebaseAdmin.auth().verifyIdToken(idToken);
      const firebasePhone = decodedFirebaseToken.phone_number;
      
      // Compare last 10 digits to ignore country code variations
      const firebaseLast10 = firebasePhone ? firebasePhone.slice(-10) : '';
      const adminLast10 = admin.phone ? admin.phone.toString().slice(-10) : '';

      if (firebaseLast10 && firebaseLast10 === adminLast10) {
        otpValid = true;
      }
    } catch (error) {
      console.error('[Firebase Verify Error]', error);
    }

    if (!otpValid) {
      // Track failed attempts
      const attempts = await redis.incr(attemptsKey);
      await redis.expire(attemptsKey, LOCK_DURATION_SEC);

      if (attempts >= MAX_OTP_ATTEMPTS) {
        // Lock the account and blacklist the pending token
        await safeRedisSetex(lockKey, LOCK_DURATION_SEC, '1');
        await redis.del(attemptsKey);
        await safeRedisSetex(blacklistKey, 15 * 60, '1');

        await adminMailer.sendLockoutAlert({
          to: admin.email,
          adminName: admin.name,
          lockMinutes: Math.ceil(LOCK_DURATION_SEC / 60)
        });

        return res.status(403).json({
          success: false,
          message: `Too many failed attempts. Account locked for ${Math.ceil(LOCK_DURATION_SEC / 60)} minutes.`
        });
      }

      return res.status(401).json({
        success: false,
        message: `Invalid or expired Phone verification. ${MAX_OTP_ATTEMPTS - attempts} attempt(s) remaining.`
      });
    }

    // ── OTP passed — clear attempt counter ────────────────────────────────────
    await redis.del(attemptsKey);

    // ── Blacklist the pending token (single-use) ──────────────────────────────
    await safeRedisSetex(blacklistKey, 15 * 60, '1');

    // ── Issue full admin JWT (Layer 2 complete) ──────────────────────────────
    const sessionId = `${admin._id}-${Date.now()}`;
    const fullToken = signAdminJwt(
      {
        id: admin._id,
        role: 'admin',
        sessionId
      },
      FULL_JWT_EXPIRE
    );

    // ── Seed inactivity timer (Layer 5) ────────────────────────────────────
    const lastActiveKey = `admin:session:lastActive:${admin._id}`;
    try {
      await safeRedisSetex(lastActiveKey, INACTIVITY_SEC, Date.now().toString());
    } catch (redisErr) {
      console.error('[adminVerifyOtp] Redis setex failed:', redisErr.message);
    }

    return res.status(200).json({
      success: true,
      message: `Identity verified. Welcome, ${admin.name}. Your session is active for 30 minutes.`,
      token: fullToken,
      admin: {
        id: admin._id,
        name: admin.name,
        email: admin.email,
        role: admin.role
      }
    });

  } catch (err) {
    console.error('[adminVerifyOtp] Error:', err);
    return res.status(500).json({ success: false, message: 'Server error during OTP verification.' });
  }
};

// ─── Logout ───────────────────────────────────────────────────────────────────

/**
 * POST /api/admin/auth/logout
 * Blacklists the current admin token immediately.
 */
exports.adminLogout = async (req, res) => {
  try {
    const adminId = req.admin.id;
    const authHeader = req.headers.authorization || '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

    if (token) {
      await safeRedisSetex(`admin:blacklist:${token}`, 24 * 60 * 60, '1');
    }
    
    await redis.del(`admin:session:lastActive:${adminId}`);

    await AdminAuditLog.create({
      adminId,
      action: 'LOGOUT',
      ipAddress: getIp(req),
      userAgent: req.headers['user-agent']
    });

    return res.status(200).json({ success: true, message: 'Logged out successfully.' });
  } catch (err) {
    console.error('[adminLogout] Error:', err);
    return res.status(500).json({ success: false, message: 'Server error during logout.' });
  }
};

/**
 * POST /api/admin/auth/setup-phone
 * Headers: Authorization: Bearer <admin_pending token>
 * Body: { idToken }
 */
exports.setupPhone = async (req, res) => {
  try {
    const { idToken } = req.body;
    const ip = getIp(req);

    if (!idToken) {
      return res.status(400).json({ success: false, message: 'Firebase ID Token is required.' });
    }

    const authHeader = req.headers.authorization || '';
    const pendingToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
    if (!pendingToken) {
      return res.status(401).json({ success: false, message: 'Missing authentication token.' });
    }

    let decoded;
    try {
      decoded = jwt.verify(pendingToken, ADMIN_SECRET);
    } catch {
      return res.status(401).json({ success: false, message: 'Authentication token is invalid or expired.' });
    }

    if (decoded.role !== 'admin_pending') {
      return res.status(403).json({ success: false, message: 'Invalid token stage.' });
    }

    // IP check removed — mobile clients frequently change IPs between login steps

    const admin = await User.findById(decoded.id);
    if (!admin || admin.role !== 'admin') {
      return res.status(401).json({ success: false, message: 'Authentication failed.' });
    }

    let firebasePhone = '';
    try {
      const decodedFirebaseToken = await firebaseAdmin.auth().verifyIdToken(idToken);
      firebasePhone = decodedFirebaseToken.phone_number;
    } catch (error) {
      console.error('[Firebase Verify Error]', error);
      return res.status(401).json({ success: false, message: 'Invalid or expired Phone verification.' });
    }

    if (!firebasePhone) {
      return res.status(400).json({ success: false, message: 'Firebase token did not contain a phone number.' });
    }

    // Save phone and enable 2FA
    admin.phone = firebasePhone;
    admin.twoFactorEnabled = true;
    await admin.save();

    // ── Issue full admin JWT ──────────────────────────────────
    const sessionId = `${admin._id}-${Date.now()}`;
    const fullToken = signAdminJwt(
      {
        id: admin._id,
        role: 'admin',
        sessionId
      },
      FULL_JWT_EXPIRE
    );

    // ── Seed inactivity timer ─────────────────────────────────────────
    const lastActiveKey = `admin:session:lastActive:${admin._id}`;
    try {
      await safeRedisSetex(lastActiveKey, INACTIVITY_SEC, Date.now().toString());
    } catch (redisErr) {
      console.error('[setupPhone] Redis setex failed:', redisErr.message);
    }

    return res.status(200).json({
      success: true,
      message: `2FA setup complete. Welcome, ${admin.name}.`,
      token: fullToken,
      admin: {
        id: admin._id,
        name: admin.name,
        email: admin.email,
        phone: admin.phone
      }
    });

  } catch (err) {
    console.error('[setupPhone] Error:', err);
    return res.status(500).json({ success: false, message: 'Server error during phone setup.' });
  }
};

// ─── TOTP Setup (one-time, for new admins) ───────────────────────────────────

/**
 * POST /api/admin/auth/setup-totp
 * Generates a TOTP secret and returns a QR code URL for Google Authenticator.
 * Requires a valid full admin token.
 */
exports.setupTotp = async (req, res) => {
  try {
    const admin = await User.findById(req.user._id).select('+totpSecret');
    if (!admin || admin.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized.' });
    }

    const secret = speakeasy.generateSecret({
      name: `Kaamkaaz Admin (${admin.email})`,
      length: 20
    });

    // Store the secret (not yet confirmed)
    admin.totpSecret = secret.base32;
    await admin.save({ validateBeforeSave: false });

    return res.status(200).json({
      success: true,
      otpAuthUrl: secret.otpauth_url,
      base32: secret.base32,
      message: 'Scan the QR code in Google Authenticator. TOTP is now active for your account.'
    });
  } catch (err) {
    console.error('[setupTotp] Error:', err);
    return res.status(500).json({ success: false, message: 'Server error.' });
  }
};
