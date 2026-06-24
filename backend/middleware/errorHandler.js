const errorHandler = (err, req, res, next) => {
  console.error('Error Trace:', err);

  let statusCode = err.statusCode || 500;
  let message = req.t('general.server_error');

  // Mongoose Validation Error
  if (err.name === 'ValidationError') {
    statusCode = 400;
    message = req.t('validation.required_field');
  }

  // Mongoose Cast Error (Bad ObjectId)
  if (err.name === 'CastError') {
    statusCode = 400;
    message = req.t('general.not_found');
  }

  // Mongoose Duplicate Key Error (code 11000)
  if (err.code === 11000) {
    statusCode = 400;
    message = 'Resource already exists'; // Translated versions can be added to JSON
  }

  // Supabase Auth Errors
  if (err.name === 'AuthApiError' || err.name === 'AuthUnknownError') {
    statusCode = err.status || 401;
    message = err.message || req.t('auth.invalid_token');
  }

  res.status(statusCode).json({
    success: false,
    message: message,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
  });
};

module.exports = errorHandler;

module.exports = errorHandler;
