const errorMap = {
  // MongoDB / Mongoose
  MONGO_CONNECTION: {
    message: "We're having trouble connecting. Please try again in a moment.",
    errorCode: 'DB_ERROR',
    statusCode: 503
  },
  VALIDATION_ERROR: {
    message: "Some details seem incorrect. Please check and try again.",
    errorCode: 'VALIDATION_ERROR',
    statusCode: 400
  },
  CAST_ERROR: {
    message: "We couldn't find what you were looking for.",
    errorCode: 'NOT_FOUND',
    statusCode: 404
  },
  DUPLICATE_KEY_DEFAULT: {
    message: "This record already exists.",
    errorCode: 'DUPLICATE_ERROR',
    statusCode: 400
  },
  DUPLICATE_KEY_PHONE: {
    message: "This phone number is already registered. Try logging in instead.",
    errorCode: 'PHONE_EXISTS',
    statusCode: 400
  },
  DUPLICATE_KEY_EMAIL: {
    message: "This email is already registered. Try logging in instead.",
    errorCode: 'EMAIL_EXISTS',
    statusCode: 400
  },

  // Auth / Supabase
  JWT_EXPIRED: {
    message: "Your session has expired. Please log in again.",
    errorCode: 'AUTH_EXPIRED',
    statusCode: 401
  },
  JWT_INVALID: {
    message: "Your session is invalid. Please log in again.",
    errorCode: 'AUTH_INVALID',
    statusCode: 401
  },
  OTP_EXPIRED: {
    message: "The OTP has expired. Please request a new one.",
    errorCode: 'OTP_EXPIRED',
    statusCode: 400
  },

  // Business Logic
  KYC_NOT_APPROVED: {
    message: "Please complete your KYC verification before applying to jobs.",
    errorCode: 'KYC_NOT_APPROVED',
    statusCode: 403
  },
  JOB_NOT_FOUND: {
    message: "This job is no longer accepting applications.",
    errorCode: 'JOB_CLOSED',
    statusCode: 404
  },
  
  // Infrastructure
  RATE_LIMIT: {
    message: "You're doing that too fast. Please wait a moment and try again.",
    errorCode: 'RATE_LIMIT',
    statusCode: 429
  },
  CLOUDINARY_ERROR: {
    message: "Document upload failed. Please check your connection and try again.",
    errorCode: 'UPLOAD_FAILED',
    statusCode: 502
  },
  REDIS_ERROR: {
    message: "Service is temporarily slow. Please try again shortly.",
    errorCode: 'CACHE_ERROR',
    statusCode: 503
  },
  BULLMQ_ERROR: {
    message: "Your request is taking longer than expected. We'll notify you once it's done.",
    errorCode: 'ASYNC_DELAY',
    statusCode: 202
  },

  // Fallback
  GENERIC_ERROR: {
    message: "Something went wrong on our end. Please try again.",
    errorCode: 'SERVER_ERROR',
    statusCode: 500
  }
};

module.exports = errorMap;
