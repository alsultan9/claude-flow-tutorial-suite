/**
 * User Routes
 * Defines all user-related API endpoints with proper validation and middleware
 */

const express = require('express');
const { UserController } = require('../controllers/UserController');
const { createAuthMiddleware } = require('../middleware/authMiddleware');
const { createError } = require('../../shared/errors');

/**
 * User Routes Factory
 * Creates Express router with all user endpoints
 * @param {Object} dependencies - Service dependencies
 * @returns {express.Router} Configured router
 */
function createUserRoutes(dependencies) {
  const {
    userService,
    userRepository,
    logger,
    rateLimiter = null,
  } = dependencies;

  if (!userService || !userRepository || !logger) {
    throw createError.config('Required dependencies missing for user routes');
  }

  const router = express.Router();
  
  // Initialize controller and middleware
  const userController = new UserController(userService, logger, rateLimiter);
  const authMiddleware = createAuthMiddleware(userRepository, logger);

  // Apply rate limiting for authentication routes
  const authRateLimit = authMiddleware.rateLimitAuth(10, 15 * 60 * 1000); // 10 attempts per 15 minutes

  /**
   * Public Routes (No Authentication Required)
   */

  // POST /api/users/register - Register new user
  router.post('/register', 
    authRateLimit,
    userController.register
  );

  // POST /api/users/login - User authentication
  router.post('/login', 
    authRateLimit,
    userController.login
  );

  // POST /api/users/logout - User logout (optional auth)
  router.post('/logout', 
    authMiddleware.optionalAuthenticate,
    userController.logout
  );

  /**
   * Protected Routes (Authentication Required)
   */

  // GET /api/users/profile - Get current user profile
  router.get('/profile',
    authMiddleware.authenticate,
    userController.getProfile
  );

  // PUT /api/users/profile - Update current user profile
  router.put('/profile',
    authMiddleware.authenticate,
    authMiddleware.requireVerified,
    userController.updateProfile
  );

  // PUT /api/users/password - Change user password
  router.put('/password',
    authMiddleware.authenticate,
    authMiddleware.requireVerified,
    userController.changePassword
  );

  // POST /api/users/verify-email - Verify email address
  router.post('/verify-email',
    authMiddleware.authenticate,
    userController.verifyEmail
  );

  // DELETE /api/users/account - Delete user account
  router.delete('/account',
    authMiddleware.authenticate,
    authMiddleware.requireVerified,
    userController.deleteAccount
  );

  /**
   * Admin-Only Routes
   */

  // GET /api/users - List all users (admin only)
  router.get('/',
    authMiddleware.authenticate,
    authMiddleware.requireRole('admin'),
    userController.listUsers
  );

  // GET /api/users/:id - Get specific user by ID (admin only)
  router.get('/:id',
    authMiddleware.authenticate,
    authMiddleware.requireRole('admin'),
    userController.getUserById
  );

  // PUT /api/users/:id/role - Update user role (admin only)
  router.put('/:id/role',
    authMiddleware.authenticate,
    authMiddleware.requireRole('admin'),
    userController.updateUserRole
  );

  // PUT /api/users/:id/deactivate - Deactivate user account (admin only)
  router.put('/:id/deactivate',
    authMiddleware.authenticate,
    authMiddleware.requireRole('admin'),
    userController.deactivateUser
  );

  /**
   * Health Check Route
   */
  router.get('/health', (req, res) => {
    res.json({
      success: true,
      message: 'User service is healthy',
      timestamp: new Date().toISOString(),
    });
  });

  /**
   * API Documentation Route (Development Only)
   */
  if (process.env.NODE_ENV === 'development') {
    router.get('/docs', (req, res) => {
      const apiDocs = {
        title: 'User API Documentation',
        version: '1.0.0',
        baseUrl: '/api/users',
        endpoints: [
          {
            method: 'POST',
            path: '/register',
            description: 'Register a new user account',
            auth: false,
            rateLimit: '5 attempts per hour per IP',
            body: {
              email: 'string (required, email format)',
              password: 'string (required, min 8 chars, complex)',
              name: 'string (required, max 100 chars)',
              profile: 'object (optional)',
            },
            responses: {
              201: 'User created successfully',
              400: 'Validation error',
              409: 'Email already exists',
              429: 'Rate limit exceeded',
            },
          },
          {
            method: 'POST',
            path: '/login',
            description: 'Authenticate user and receive access token',
            auth: false,
            rateLimit: '10 attempts per hour per email',
            body: {
              email: 'string (required, email format)',
              password: 'string (required)',
            },
            responses: {
              200: 'Authentication successful',
              401: 'Invalid credentials',
              429: 'Rate limit exceeded',
            },
          },
          {
            method: 'GET',
            path: '/profile',
            description: 'Get current user profile',
            auth: true,
            responses: {
              200: 'Profile retrieved successfully',
              401: 'Authentication required',
            },
          },
          {
            method: 'PUT',
            path: '/profile',
            description: 'Update current user profile',
            auth: true,
            verified: true,
            body: {
              name: 'string (optional, max 100 chars)',
              email: 'string (optional, email format)',
              profile: 'object (optional)',
            },
            responses: {
              200: 'Profile updated successfully',
              400: 'Validation error',
              401: 'Authentication required',
              409: 'Email already exists',
            },
          },
          {
            method: 'PUT',
            path: '/password',
            description: 'Change user password',
            auth: true,
            verified: true,
            rateLimit: '3 attempts per hour per user',
            body: {
              currentPassword: 'string (required)',
              newPassword: 'string (required, min 8 chars, complex)',
            },
            responses: {
              200: 'Password changed successfully',
              400: 'Validation error',
              401: 'Invalid current password',
              429: 'Rate limit exceeded',
            },
          },
          {
            method: 'POST',
            path: '/verify-email',
            description: 'Verify email address with token',
            auth: true,
            body: {
              token: 'string (required)',
            },
            responses: {
              200: 'Email verified successfully',
              400: 'Invalid or expired token',
              401: 'Authentication required',
            },
          },
          {
            method: 'DELETE',
            path: '/account',
            description: 'Delete user account permanently',
            auth: true,
            verified: true,
            rateLimit: '1 attempt per day per user',
            responses: {
              200: 'Account deleted successfully',
              401: 'Authentication required',
              429: 'Rate limit exceeded',
            },
          },
          {
            method: 'GET',
            path: '/',
            description: 'List all users with filtering and pagination',
            auth: true,
            role: 'admin',
            query: {
              page: 'number (optional, default: 1)',
              limit: 'number (optional, default: 10, max: 100)',
              role: 'string (optional, enum: user|moderator|admin|guest)',
              status: 'string (optional, enum: active|inactive|suspended|pending)',
              verified: 'boolean (optional)',
              search: 'string (optional, searches name and email)',
            },
            responses: {
              200: 'Users retrieved successfully',
              401: 'Authentication required',
              403: 'Admin access required',
            },
          },
          {
            method: 'GET',
            path: '/:id',
            description: 'Get specific user by ID',
            auth: true,
            role: 'admin',
            responses: {
              200: 'User retrieved successfully',
              401: 'Authentication required',
              403: 'Admin access required',
              404: 'User not found',
            },
          },
          {
            method: 'PUT',
            path: '/:id/role',
            description: 'Update user role',
            auth: true,
            role: 'admin',
            body: {
              role: 'string (required, enum: user|moderator|admin|guest)',
            },
            responses: {
              200: 'Role updated successfully',
              400: 'Cannot change own role',
              401: 'Authentication required',
              403: 'Admin access required',
              404: 'User not found',
            },
          },
          {
            method: 'PUT',
            path: '/:id/deactivate',
            description: 'Deactivate user account',
            auth: true,
            role: 'admin',
            body: {
              reason: 'string (required)',
            },
            responses: {
              200: 'User deactivated successfully',
              400: 'Cannot deactivate own account',
              401: 'Authentication required',
              403: 'Admin access required',
              404: 'User not found',
            },
          },
          {
            method: 'POST',
            path: '/logout',
            description: 'Logout user (clears session cookies)',
            auth: false,
            responses: {
              200: 'Logged out successfully',
            },
          },
          {
            method: 'GET',
            path: '/health',
            description: 'Service health check',
            auth: false,
            responses: {
              200: 'Service is healthy',
            },
          },
        ],
        authentication: {
          type: 'Bearer Token (JWT)',
          header: 'Authorization: Bearer <token>',
          cookie: 'accessToken',
          expiration: '24 hours',
        },
        errorResponses: {
          400: 'Bad Request - Validation failed',
          401: 'Unauthorized - Authentication required',
          403: 'Forbidden - Insufficient permissions',
          404: 'Not Found - Resource not found',
          409: 'Conflict - Resource already exists',
          422: 'Unprocessable Entity - Business rule violation',
          429: 'Too Many Requests - Rate limit exceeded',
          500: 'Internal Server Error - Server error',
        },
      };

      res.json(apiDocs);
    });
  }

  return router;
}

/**
 * Create mock user routes for testing
 * @param {Object} mockUserService - Mock user service
 * @param {Object} mockLogger - Mock logger
 * @returns {express.Router} Mock router
 */
function createMockUserRoutes(mockUserService, mockLogger) {
  const router = express.Router();

  // Simple mock implementations for testing
  router.post('/register', (req, res) => {
    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: { user: { id: 'test-123', email: req.body.email } },
    });
  });

  router.post('/login', (req, res) => {
    res.json({
      success: true,
      message: 'Authentication successful',
      data: { 
        user: { id: 'test-123', email: req.body.email },
        token: 'mock-jwt-token',
      },
    });
  });

  router.get('/profile', (req, res) => {
    res.json({
      success: true,
      data: { 
        profile: { 
          id: 'test-123', 
          email: 'test@example.com',
          name: 'Test User',
        },
      },
    });
  });

  return router;
}

module.exports = {
  createUserRoutes,
  createMockUserRoutes,
};