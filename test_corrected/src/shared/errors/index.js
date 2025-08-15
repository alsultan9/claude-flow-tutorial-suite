/**
 * Custom Error Classes and Error Handling Utilities
 * Provides structured error handling with proper HTTP status codes and logging
 */

/**
 * Base Application Error Class
 */
class AppError extends Error {
  constructor(message, statusCode = 500, code = 'INTERNAL_ERROR', metadata = {}) {
    super(message);
    
    this.name = this.constructor.name;
    this.statusCode = statusCode;
    this.code = code;
    this.metadata = metadata;
    this.timestamp = new Date().toISOString();
    this.isOperational = true;
    
    // Capture stack trace, excluding constructor call from it
    Error.captureStackTrace(this, this.constructor);
  }

  /**
   * Convert error to JSON for logging/response
   * @returns {Object}
   */
  toJSON() {
    return {
      name: this.name,
      message: this.message,
      code: this.code,
      statusCode: this.statusCode,
      metadata: this.metadata,
      timestamp: this.timestamp,
      stack: this.stack,
    };
  }

  /**
   * Get client-safe error response
   * @returns {Object}
   */
  toClientResponse() {
    return {
      error: {
        code: this.code,
        message: this.message,
        timestamp: this.timestamp,
        ...(this.metadata && Object.keys(this.metadata).length > 0 && { details: this.metadata }),
      },
    };
  }
}

/**
 * Validation Error (400)
 */
class ValidationError extends AppError {
  constructor(message, errors = [], field = null) {
    super(message, 400, 'VALIDATION_ERROR', {
      field,
      errors: Array.isArray(errors) ? errors : [errors],
    });
  }

  static fromJoiError(joiError) {
    const errors = joiError.details.map(detail => ({
      field: detail.path.join('.'),
      message: detail.message,
      value: detail.context.value,
    }));

    return new ValidationError(
      'Validation failed',
      errors
    );
  }

  static fromZodError(zodError) {
    const errors = zodError.errors.map(error => ({
      field: error.path.join('.'),
      message: error.message,
      code: error.code,
    }));

    return new ValidationError(
      'Validation failed',
      errors
    );
  }
}

/**
 * Authentication Error (401)
 */
class AuthenticationError extends AppError {
  constructor(message = 'Authentication required', code = 'AUTH_REQUIRED') {
    super(message, 401, code);
  }
}

/**
 * Authorization Error (403)
 */
class AuthorizationError extends AppError {
  constructor(message = 'Access forbidden', requiredPermission = null) {
    super(message, 403, 'ACCESS_FORBIDDEN', {
      requiredPermission,
    });
  }
}

/**
 * Not Found Error (404)
 */
class NotFoundError extends AppError {
  constructor(resource = 'Resource', id = null) {
    const message = id ? `${resource} with ID '${id}' not found` : `${resource} not found`;
    super(message, 404, 'NOT_FOUND', { resource, id });
  }
}

/**
 * Conflict Error (409)
 */
class ConflictError extends AppError {
  constructor(message, conflictingField = null, conflictingValue = null) {
    super(message, 409, 'CONFLICT', {
      field: conflictingField,
      value: conflictingValue,
    });
  }
}

/**
 * Rate Limit Error (429)
 */
class RateLimitError extends AppError {
  constructor(limit, windowMs, retryAfter = null) {
    super(
      `Rate limit exceeded: ${limit} requests per ${windowMs}ms`,
      429,
      'RATE_LIMIT_EXCEEDED',
      { limit, windowMs, retryAfter }
    );
  }
}

/**
 * Database Error (500)
 */
class DatabaseError extends AppError {
  constructor(message, originalError = null, query = null) {
    super(message, 500, 'DATABASE_ERROR', {
      originalError: originalError?.message,
      query: query ? query.substring(0, 200) : null, // Truncate long queries
    });
  }
}

/**
 * External Service Error (502)
 */
class ExternalServiceError extends AppError {
  constructor(serviceName, message, originalError = null) {
    super(
      `External service error (${serviceName}): ${message}`,
      502,
      'EXTERNAL_SERVICE_ERROR',
      {
        serviceName,
        originalError: originalError?.message,
      }
    );
  }
}

/**
 * Business Logic Error (422)
 */
class BusinessError extends AppError {
  constructor(message, businessRule = null) {
    super(message, 422, 'BUSINESS_RULE_VIOLATION', {
      businessRule,
    });
  }
}

/**
 * Configuration Error (500)
 */
class ConfigurationError extends AppError {
  constructor(message, configKey = null) {
    super(message, 500, 'CONFIGURATION_ERROR', {
      configKey,
    });
  }
}

/**
 * Error Handler Utility Functions
 */
class ErrorHandler {
  /**
   * Check if error is operational (expected) vs programming error
   * @param {Error} error
   * @returns {boolean}
   */
  static isOperationalError(error) {
    if (error instanceof AppError) {
      return error.isOperational;
    }
    return false;
  }

  /**
   * Log error with appropriate level
   * @param {Error} error
   * @param {Object} logger
   * @param {Object} context - Additional context for logging
   */
  static logError(error, logger, context = {}) {
    const errorLog = {
      ...context,
      error: {
        name: error.name,
        message: error.message,
        stack: error.stack,
        ...(error instanceof AppError && {
          code: error.code,
          statusCode: error.statusCode,
          metadata: error.metadata,
        }),
      },
      timestamp: new Date().toISOString(),
    };

    if (error instanceof AppError && error.statusCode < 500) {
      logger.warn('Client error occurred', errorLog);
    } else {
      logger.error('Server error occurred', errorLog);
    }
  }

  /**
   * Handle async errors in Express routes
   * @param {Function} fn - Async route handler
   * @returns {Function} Express middleware
   */
  static asyncHandler(fn) {
    return (req, res, next) => {
      Promise.resolve(fn(req, res, next)).catch(next);
    };
  }

  /**
   * Express error handling middleware
   * @param {Error} error
   * @param {Object} req
   * @param {Object} res
   * @param {Function} next
   */
  static expressErrorHandler(error, req, res, next) {
    // Log error
    if (req.logger) {
      ErrorHandler.logError(error, req.logger, {
        method: req.method,
        url: req.url,
        userAgent: req.get('User-Agent'),
        ip: req.ip,
        userId: req.user?.id,
      });
    }

    // Don't leak error details in production for non-operational errors
    if (error instanceof AppError) {
      return res.status(error.statusCode).json(error.toClientResponse());
    }

    // Handle specific non-AppError types
    if (error.name === 'ValidationError' && error.errors) {
      const validationError = new ValidationError('Validation failed', error.errors);
      return res.status(validationError.statusCode).json(validationError.toClientResponse());
    }

    if (error.name === 'CastError') {
      const castError = new ValidationError(`Invalid ${error.path}: ${error.value}`);
      return res.status(castError.statusCode).json(castError.toClientResponse());
    }

    if (error.code === 11000) { // MongoDB duplicate key
      const field = Object.keys(error.keyValue)[0];
      const conflictError = new ConflictError(`${field} already exists`, field, error.keyValue[field]);
      return res.status(conflictError.statusCode).json(conflictError.toClientResponse());
    }

    // Generic server error
    const genericError = new AppError(
      process.env.NODE_ENV === 'production' ? 'Internal server error' : error.message
    );
    
    res.status(genericError.statusCode).json(genericError.toClientResponse());
  }

  /**
   * Handle uncaught exceptions and unhandled rejections
   * @param {Object} logger
   */
  static handleUncaughtExceptions(logger) {
    process.on('uncaughtException', (error) => {
      logger.error('Uncaught Exception:', {
        error: {
          name: error.name,
          message: error.message,
          stack: error.stack,
        },
      });
      
      process.exit(1);
    });

    process.on('unhandledRejection', (reason, promise) => {
      logger.error('Unhandled Rejection at:', {
        promise,
        reason: reason instanceof Error ? {
          name: reason.name,
          message: reason.message,
          stack: reason.stack,
        } : reason,
      });
      
      process.exit(1);
    });
  }
}

/**
 * Error Factory Functions
 */
const createError = {
  validation: (message, errors, field) => new ValidationError(message, errors, field),
  auth: (message, code) => new AuthenticationError(message, code),
  forbidden: (message, requiredPermission) => new AuthorizationError(message, requiredPermission),
  notFound: (resource, id) => new NotFoundError(resource, id),
  conflict: (message, field, value) => new ConflictError(message, field, value),
  rateLimit: (limit, windowMs, retryAfter) => new RateLimitError(limit, windowMs, retryAfter),
  database: (message, originalError, query) => new DatabaseError(message, originalError, query),
  external: (serviceName, message, originalError) => new ExternalServiceError(serviceName, message, originalError),
  business: (message, businessRule) => new BusinessError(message, businessRule),
  config: (message, configKey) => new ConfigurationError(message, configKey),
};

module.exports = {
  // Error Classes
  AppError,
  ValidationError,
  AuthenticationError,
  AuthorizationError,
  NotFoundError,
  ConflictError,
  RateLimitError,
  DatabaseError,
  ExternalServiceError,
  BusinessError,
  ConfigurationError,
  
  // Utilities
  ErrorHandler,
  createError,
  
  // Express middleware
  asyncHandler: ErrorHandler.asyncHandler,
  errorHandler: ErrorHandler.expressErrorHandler,
};