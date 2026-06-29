/**
 * validateRequest.js — Section 5.1: Validation Error Handler
 *
 * Reads express-validator errors and returns a unified 400 response.
 * Place this AFTER validator arrays and BEFORE the route handler.
 *
 * Usage:
 *   router.post('/register', registerValidator, validateRequest, register);
 */

const { validationResult } = require('express-validator');

const validateRequest = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const firstError = errors.array({ onlyFirstError: true })[0];
    return res.status(400).json({
      success: false,
      message: firstError.msg,
      field:   firstError.path || firstError.param,
      errors:  errors.array({ onlyFirstError: true }).map(e => ({
        field:   e.path || e.param,
        message: e.msg
      }))
    });
  }
  next();
};

module.exports = validateRequest;
