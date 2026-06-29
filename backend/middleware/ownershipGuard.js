/**
 * ownershipGuard.js — Section 2.2: IDOR Prevention
 *
 * Factory that creates ownership-check middleware for any Mongoose model.
 * Always returns 403 (never 404) when ownership fails — prevents resource existence leaking.
 *
 * Usage:
 *   const { assertOwnership } = require('../middleware/ownershipGuard');
 *   router.get('/applications/:id', protect, assertOwnership(Application, 'id', 'workerId'), handler);
 *
 * For recruiter ownership (e.g. job owner):
 *   assertOwnership(Job, 'id', 'recruiterId')
 *
 * For admin bypass (admin can access all):
 *   assertOwnership(Application, 'id', 'workerId', { adminBypass: true })
 */

const mongoose = require('mongoose');

/**
 * @param {mongoose.Model} Model         — Mongoose model to query
 * @param {string}         idParam       — req.params key containing the document _id
 * @param {string}         ownerField    — field on the document that must equal req.user.id
 * @param {object}         opts
 * @param {boolean}        opts.adminBypass — if true, admin role skips the check (default: true)
 */
exports.assertOwnership = (Model, idParam, ownerField, opts = {}) => {
  const { adminBypass = true } = opts;

  return async (req, res, next) => {
    // Admin bypass
    if (adminBypass && req.user?.role === 'admin') return next();

    const docId = req.params[idParam];
    if (!docId || !mongoose.isValidObjectId(docId)) {
      return res.status(403).json({ success: false, message: 'Access denied.' });
    }

    const doc = await Model.findById(docId).select(ownerField).lean();
    if (!doc) {
      // Return 403, NOT 404 — never leak existence
      return res.status(403).json({ success: false, message: 'Access denied.' });
    }

    const ownerId = doc[ownerField]?.toString?.() || doc[ownerField];
    if (ownerId !== req.user.id.toString()) {
      return res.status(403).json({ success: false, message: 'Access denied.' });
    }

    next();
  };
};

/**
 * Verify that the current user owns a resource via a nested path.
 * Example: job.recruiterId for application → job ownership check.
 *
 * @param {mongoose.Model} Model    — e.g. Application
 * @param {string}         idParam  — req.params key
 * @param {string}         populate — field to populate (e.g. 'jobId')
 * @param {string}         path     — dotted path to owner on populated doc (e.g. 'jobId.recruiterId')
 */
exports.assertNestedOwnership = (Model, idParam, populate, path) => {
  return async (req, res, next) => {
    if (req.user?.role === 'admin') return next();

    const docId = req.params[idParam];
    if (!docId || !mongoose.isValidObjectId(docId)) {
      return res.status(403).json({ success: false, message: 'Access denied.' });
    }

    const doc = await Model.findById(docId).populate(populate).lean();
    if (!doc) {
      return res.status(403).json({ success: false, message: 'Access denied.' });
    }

    // Resolve dotted path
    const ownerId = path.split('.').reduce((obj, key) => obj?.[key], doc)?.toString?.();
    if (!ownerId || ownerId !== req.user.id.toString()) {
      return res.status(403).json({ success: false, message: 'Access denied.' });
    }

    next();
  };
};
