/**
 * authValidators.js — Section 5.1: Input Validation for Auth Routes
 * Uses express-validator. Apply before the route handler.
 *
 * Usage:
 *   const { registerValidator, loginValidator } = require('./validators/authValidators');
 *   router.post('/register', registerValidator, validateRequest, register);
 */

const { body } = require('express-validator');

// ─── Register ─────────────────────────────────────────────────────────────────
exports.registerValidator = [
  body('name')
    .trim()
    .notEmpty().withMessage('Name is required.')
    .isLength({ max: 60 }).withMessage('Name cannot exceed 60 characters.')
    .matches(/^[a-zA-Z\u0900-\u097F\s]+$/).withMessage('Name must contain only letters and spaces.'),

  body('phone')
    .trim()
    .notEmpty().withMessage('Phone number is required.')
    .matches(/^\d{10}$/).withMessage('Phone must be a 10-digit number.'),

  body('email')
    .trim()
    .notEmpty().withMessage('Email is required.')
    .isEmail().withMessage('A valid email address is required.')
    .normalizeEmail(),

  body('password')
    .notEmpty().withMessage('Password is required.')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters.')
    .matches(/\d/).withMessage('Password must contain at least one number.')
    .matches(/[!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?]/)
    .withMessage('Password must contain at least one special character.'),

  body('aadhaarNumber')
    .trim()
    .notEmpty().withMessage('Aadhaar number is required.')
    .matches(/^\d{12}$/).withMessage('Aadhaar must be exactly 12 digits.'),

  body('role')
    .optional()
    .isIn(['worker', 'recruiter']).withMessage('Role must be worker or recruiter.'),
];

// ─── Login ────────────────────────────────────────────────────────────────────
exports.loginValidator = [
  body('password')
    .notEmpty().withMessage('Password is required.'),

  // At least one of phone or email must be provided
  body('phone')
    .optional()
    .matches(/^\d{10}$/).withMessage('Phone must be a 10-digit number.'),

  body('email')
    .optional()
    .isEmail().withMessage('A valid email address is required.')
    .normalizeEmail(),
];

// ─── Change Password ──────────────────────────────────────────────────────────
exports.changePasswordValidator = [
  body('oldPassword')
    .notEmpty().withMessage('Current password is required.'),

  body('newPassword')
    .notEmpty().withMessage('New password is required.')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters.')
    .matches(/\d/).withMessage('New password must contain at least one number.')
    .matches(/[!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?]/)
    .withMessage('New password must contain at least one special character.'),
];

// ─── Reset Password ───────────────────────────────────────────────────────────
exports.resetPasswordValidator = [
  body('resetToken')
    .notEmpty().withMessage('Reset token is required.'),

  body('newPassword')
    .notEmpty().withMessage('New password is required.')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters.')
    .matches(/\d/).withMessage('Must contain at least one number.')
    .matches(/[!@#$%^&*()_+\-=[\]{};':"\\|,.<>/?]/)
    .withMessage('Must contain at least one special character.'),
];
