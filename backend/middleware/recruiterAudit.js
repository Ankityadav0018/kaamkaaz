/**
 * recruiterAudit.js — Section 4: Recruiter Personal Data Access Logging
 *
 * Middleware factory that logs recruiter access to worker personal data.
 * Apply to any route that exposes worker contact info or personal profiles.
 *
 * Usage:
 *   const recruiterAudit = require('../middleware/recruiterAudit');
 *   router.get('/applications/:id/worker-profile',
 *     protect, authorize('recruiter'),
 *     recruiterAudit('view_contact'),
 *     handler
 *   );
 */

const RecruiterAuditLog = require('../models/RecruiterAuditLog');

const getIp = (req) =>
  (req.headers['x-forwarded-for'] || '').split(',')[0].trim()
  || req.socket.remoteAddress
  || '0.0.0.0';

/**
 * @param {string} action — e.g. 'view_worker_profile', 'view_contact', 'view_applications'
 * @param {object} opts
 * @param {string} opts.workerIdParam — req.params key containing target worker ID (optional)
 * @param {string} opts.jobIdParam    — req.params key containing job ID (optional)
 */
const recruiterAudit = (action, opts = {}) => {
  return (req, res, next) => {
    // Fire-and-forget — never block the actual request
    RecruiterAuditLog.create({
      recruiterId:    req.user?._id,
      action,
      targetWorkerId: opts.workerIdParam ? req.params[opts.workerIdParam] : null,
      relatedJobId:   opts.jobIdParam    ? req.params[opts.jobIdParam]    : null,
      ip:             getIp(req),
      meta: {
        route:  req.originalUrl,
        method: req.method
      }
    }).catch(err => console.error('[RecruiterAudit] Log error:', err.message));

    next();
  };
};

module.exports = recruiterAudit;
