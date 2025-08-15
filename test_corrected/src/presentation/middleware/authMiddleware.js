/**
 * Authentication Middleware
 * Handles JWT token validation and user authentication for protected routes
 */

const jwt = require('jsonwebtoken');
const { createError } = require('../../shared/errors');
const { config } = require('../../shared/config');

/**
 * JWT Authentication Middleware
 * Validates JWT tokens and attaches user information to request
 */
class AuthMiddleware {
  constructor(userRepository, logger, tokenSecret = null) {
    this.userRepository = userRepository;
    this.logger = logger;
    this.tokenSecret = tokenSecret || config.get('auth.jwt.secret');
    this.tokenIssuer = config.get('auth.jwt.issuer');
    this.tokenAudience = config.get('auth.jwt.audience');
  }

  /**
   * Authenticate JWT token
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   * @param {Function} next - Express next function
   */
  authenticate = async (req, res, next) => {
    try {
      const token = this._extractToken(req);

      if (!token) {
        throw createError.auth('Authentication token required', 'TOKEN_REQUIRED');
      }

      // Verify and decode token
      const decoded = this._verifyToken(token);

      // Load user from database
      const user = await this.userRepository.findById(decoded.userId);
      if (!user) {
        throw createError.auth('User not found', 'USER_NOT_FOUND');
      }

      // Check if user is active
      if (user.status !== 'active') {
        throw createError.auth('Account is not active', 'ACCOUNT_INACTIVE');
      }

      // Attach user to request
      req.user = {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        permissions: user.permissions || [],
        verified: user.verified,
        lastLoginAt: user.lastLoginAt,
      };

      req.token = {
        raw: token,
        decoded,
      };

      this.logger?.debug('User authenticated successfully', {
        userId: user.id,
        email: user.email,
        role: user.role,
      });

      next();
    } catch (error) {
      this._handleAuthError(error, req, res, next);
    }
  };

  /**
   * Optional authentication (doesn't fail if no token)
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   * @param {Function} next - Express next function
   */
  optionalAuthenticate = async (req, res, next) => {
    try {
      const token = this._extractToken(req);

      if (!token) {
        // No token provided, continue without authentication
        req.user = null;
        req.token = null;
        return next();
      }

      // Use the regular authenticate logic
      await this.authenticate(req, res, next);
    } catch (error) {
      // For optional auth, continue without user if authentication fails
      req.user = null;
      req.token = null;
      next();
    }
  };

  /**
   * Require specific role
   * @param {...string} roles - Required roles
   * @returns {Function} Express middleware
   */
  requireRole = (...roles) => {
    return (req, res, next) => {
      if (!req.user) {
        return next(createError.auth('Authentication required', 'AUTH_REQUIRED'));
      }

      if (!roles.includes(req.user.role)) {
        return next(createError.forbidden(
          `Access denied. Required role: ${roles.join(' or ')}`,
          roles[0]
        ));
      }

      next();
    };
  };

  /**
   * Require specific permission
   * @param {...string} permissions - Required permissions
   * @returns {Function} Express middleware
   */
  requirePermission = (...permissions) => {
    return (req, res, next) => {
      if (!req.user) {
        return next(createError.auth('Authentication required', 'AUTH_REQUIRED'));
      }

      const userPermissions = req.user.permissions || [];
      const hasPermission = permissions.some(perm => userPermissions.includes(perm));

      if (!hasPermission) {
        return next(createError.forbidden(
          `Access denied. Required permission: ${permissions.join(' or ')}`,
          permissions[0]
        ));
      }

      next();
    };
  };

  /**
   * Require user to be verified
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   * @param {Function} next - Express next function
   */
  requireVerified = (req, res, next) => {
    if (!req.user) {
      return next(createError.auth('Authentication required', 'AUTH_REQUIRED'));
    }

    if (!req.user.verified) {
      return next(createError.auth('Email verification required', 'VERIFICATION_REQUIRED'));
    }

    next();
  };

  /**
   * Require user to own the resource (matches user ID in URL params)
   * @param {string} paramName - Parameter name containing user ID (default: 'id')
   * @returns {Function} Express middleware
   */
  requireOwnership = (paramName = 'id') => {
    return (req, res, next) => {
      if (!req.user) {
        return next(createError.auth('Authentication required', 'AUTH_REQUIRED'));
      }

      const resourceUserId = req.params[paramName];
      
      // Admin can access any resource
      if (req.user.role === 'admin') {
        return next();
      }

      // User can only access their own resources
      if (req.user.id !== resourceUserId) {
        return next(createError.forbidden('Access denied. You can only access your own resources'));
      }

      next();
    };
  };

  /**
   * Rate limiting for authentication attempts
   * @param {number} maxAttempts - Maximum attempts per window
   * @param {number} windowMs - Time window in milliseconds
   * @returns {Function} Express middleware
   */
  rateLimitAuth = (maxAttempts = 10, windowMs = 15 * 60 * 1000) => {
    const attempts = new Map();

    return (req, res, next) => {
      const key = this._getClientKey(req);
      const now = Date.now();
      
      // Clean old entries
      for (const [clientKey, data] of attempts) {
        if (now - data.firstAttempt > windowMs) {
          attempts.delete(clientKey);
        }
      }

      const clientAttempts = attempts.get(key);
      
      if (clientAttempts) {
        if (clientAttempts.count >= maxAttempts) {
          const resetTime = clientAttempts.firstAttempt + windowMs;
          const retryAfter = Math.ceil((resetTime - now) / 1000);
          
          res.set('Retry-After', retryAfter);
          return next(createError.rateLimit(maxAttempts, windowMs, retryAfter));
        }
        
        clientAttempts.count++;
      } else {
        attempts.set(key, { count: 1, firstAttempt: now });
      }

      next();
    };
  };

  /**
   * Generate a new JWT token
   * @param {Object} payload - Token payload
   * @param {string} expiresIn - Token expiration time
   * @returns {string} JWT token
   */
  generateToken(payload, expiresIn = null) {
    const tokenOptions = {
      issuer: this.tokenIssuer,
      audience: this.tokenAudience,
      expiresIn: expiresIn || config.get('auth.jwt.expiresIn'),
    };

    return jwt.sign(payload, this.tokenSecret, tokenOptions);
  }

  /**
   * Generate a refresh token
   * @param {Object} payload - Token payload
   * @returns {string} Refresh token
   */
  generateRefreshToken(payload) {
    const tokenOptions = {
      issuer: this.tokenIssuer,
      audience: this.tokenAudience,
      expiresIn: config.get('auth.jwt.refreshExpiresIn'),
    };

    return jwt.sign(payload, this.tokenSecret, tokenOptions);
  }

  /**
   * Extract token from request headers or cookies
   * @private
   * @param {Object} req - Express request object
   * @returns {string|null} JWT token
   */
  _extractToken(req) {
    // Check Authorization header
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7);
    }

    // Check cookies
    if (req.cookies && req.cookies.accessToken) {
      return req.cookies.accessToken;
    }

    // Check query parameter (less secure, for development only)
    if (req.query.token && config.isDevelopment()) {
      return req.query.token;
    }

    return null;
  }

  /**
   * Verify JWT token
   * @private
   * @param {string} token - JWT token
   * @returns {Object} Decoded token payload
   */
  _verifyToken(token) {
    try {
      const options = {
        issuer: this.tokenIssuer,
        audience: this.tokenAudience,
      };

      return jwt.verify(token, this.tokenSecret, options);
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        throw createError.auth('Token has expired', 'TOKEN_EXPIRED');
      } else if (error.name === 'JsonWebTokenError') {
        throw createError.auth('Invalid token', 'INVALID_TOKEN');
      } else if (error.name === 'NotBeforeError') {
        throw createError.auth('Token not active yet', 'TOKEN_NOT_ACTIVE');
      } else {
        throw createError.auth('Token verification failed', 'TOKEN_VERIFICATION_FAILED');
      }
    }
  }

  /**
   * Handle authentication errors
   * @private
   * @param {Error} error - Authentication error
   * @param {Object} req - Express request object
   * @param {Object} res - Express response object
   * @param {Function} next - Express next function
   */
  _handleAuthError(error, req, res, next) {
    this.logger?.warn('Authentication failed', {
      error: error.message,
      code: error.code,
      ip: req.ip,
      userAgent: req.get('User-Agent'),
      path: req.path,
    });

    next(error);
  }

  /**
   * Get client identifier for rate limiting
   * @private
   * @param {Object} req - Express request object
   * @returns {string} Client key
   */
  _getClientKey(req) {
    // Use IP address and User-Agent for identification
    return `${req.ip}_${req.get('User-Agent') || 'unknown'}`;
  }
}

/**
 * Create authentication middleware factory
 * @param {Object} userRepository - User repository instance
 * @param {Object} logger - Logger instance
 * @param {string} tokenSecret - JWT secret (optional)
 * @returns {AuthMiddleware} Authentication middleware instance
 */
function createAuthMiddleware(userRepository, logger, tokenSecret = null) {
  return new AuthMiddleware(userRepository, logger, tokenSecret);
}

/**
 * Create mock authentication middleware for testing
 * @returns {Object} Mock middleware functions
 */
function createMockAuthMiddleware() {
  return {
    authenticate: (req, res, next) => {
      req.user = {
        id: 'test-user-123',
        email: 'test@example.com',
        name: 'Test User',
        role: 'user',
        permissions: ['read', 'write'],
        verified: true,
      };
      next();
    },
    
    optionalAuthenticate: (req, res, next) => {
      req.user = null;
      next();
    },
    
    requireRole: (...roles) => (req, res, next) => {
      if (!req.user || !roles.includes(req.user.role)) {
        return next(createError.forbidden('Access denied'));
      }
      next();
    },
    
    requirePermission: (...permissions) => (req, res, next) => {
      if (!req.user || !permissions.some(p => req.user.permissions.includes(p))) {
        return next(createError.forbidden('Access denied'));
      }
      next();
    },
    
    requireVerified: (req, res, next) => {
      if (!req.user || !req.user.verified) {
        return next(createError.auth('Verification required'));
      }
      next();
    },
    
    requireOwnership: (paramName = 'id') => (req, res, next) => {
      if (!req.user || (req.user.role !== 'admin' && req.user.id !== req.params[paramName])) {
        return next(createError.forbidden('Access denied'));
      }
      next();
    },
    
    rateLimitAuth: () => (req, res, next) => next(),
    
    generateToken: (payload) => 'mock-jwt-token',
    generateRefreshToken: (payload) => 'mock-refresh-token',
  };
}

module.exports = {
  AuthMiddleware,
  createAuthMiddleware,
  createMockAuthMiddleware,
};