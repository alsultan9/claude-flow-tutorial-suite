/**
 * User Controller (Presentation Layer)
 * Handles HTTP requests and responses for user operations
 * Follows REST API conventions with proper validation and error handling
 */

const { z } = require('zod');
const { createError, asyncHandler } = require('../../shared/errors');

/**
 * Validation Schemas
 */
const RegisterSchema = z.object({
  email: z.string().email('Invalid email format').min(1, 'Email is required'),
  password: z.string()
    .min(8, 'Password must be at least 8 characters long')
    .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/, 
      'Password must contain uppercase, lowercase, number, and special character'),
  name: z.string().min(1, 'Name is required').max(100, 'Name too long'),
  profile: z.object({
    firstName: z.string().optional(),
    lastName: z.string().optional(),
    phone: z.string().optional(),
  }).optional(),
});

const LoginSchema = z.object({
  email: z.string().email('Invalid email format').min(1, 'Email is required'),
  password: z.string().min(1, 'Password is required'),
});

const UpdateProfileSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  email: z.string().email().optional(),
  profile: z.object({
    firstName: z.string().max(50).optional(),
    lastName: z.string().max(50).optional(),
    phone: z.string().regex(/^\+?[\d\s\-\(\)]+$/, 'Invalid phone format').optional(),
    address: z.object({
      street: z.string().optional(),
      city: z.string().optional(),
      state: z.string().optional(),
      zipCode: z.string().optional(),
      country: z.string().optional(),
    }).optional(),
    dateOfBirth: z.string().datetime().optional(),
    preferences: z.object({
      notifications: z.boolean().optional(),
      theme: z.enum(['light', 'dark']).optional(),
      language: z.string().optional(),
    }).optional(),
  }).optional(),
});

const ChangePasswordSchema = z.object({
  currentPassword: z.string().min(1, 'Current password is required'),
  newPassword: z.string()
    .min(8, 'New password must be at least 8 characters long')
    .regex(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/, 
      'New password must contain uppercase, lowercase, number, and special character'),
});

const ListUsersSchema = z.object({
  page: z.string().transform(val => parseInt(val)).pipe(z.number().min(1)).optional(),
  limit: z.string().transform(val => parseInt(val)).pipe(z.number().min(1).max(100)).optional(),
  role: z.enum(['user', 'moderator', 'admin', 'guest']).optional(),
  status: z.enum(['active', 'inactive', 'suspended', 'pending']).optional(),
  verified: z.string().transform(val => val === 'true').pipe(z.boolean()).optional(),
  search: z.string().min(1).optional(),
});

const UpdateRoleSchema = z.object({
  role: z.enum(['user', 'moderator', 'admin', 'guest']),
});

/**
 * User Controller Class
 */
class UserController {
  constructor(userService, logger, rateLimiter = null) {
    this.userService = userService;
    this.logger = logger;
    this.rateLimiter = rateLimiter;
  }

  /**
   * Register a new user
   * POST /api/users/register
   */
  register = asyncHandler(async (req, res) => {
    // Validate request body
    const validationResult = RegisterSchema.safeParse(req.body);
    if (!validationResult.success) {
      throw createError.validation('Invalid registration data', validationResult.error.errors);
    }

    const userData = validationResult.data;

    // Apply rate limiting for registration
    if (this.rateLimiter) {
      await this.rateLimiter.checkLimit(`register:${req.ip}`, 5, 3600); // 5 attempts per hour
    }

    // Register user
    const result = await this.userService.register(userData);

    this.logger.info('User registered successfully', {
      userId: result.user.id,
      email: result.user.email,
      ip: req.ip,
    });

    res.status(201).json({
      success: true,
      message: result.message,
      data: {
        user: result.user,
      },
    });
  });

  /**
   * Authenticate user
   * POST /api/users/login
   */
  login = asyncHandler(async (req, res) => {
    // Validate request body
    const validationResult = LoginSchema.safeParse(req.body);
    if (!validationResult.success) {
      throw createError.validation('Invalid login data', validationResult.error.errors);
    }

    const { email, password } = validationResult.data;

    // Apply rate limiting for login attempts
    if (this.rateLimiter) {
      await this.rateLimiter.checkLimit(`login:${email}`, 10, 3600); // 10 attempts per hour
    }

    // Authenticate user
    const result = await this.userService.authenticate(email, password);

    this.logger.info('User authenticated successfully', {
      userId: result.user.id,
      email: result.user.email,
      ip: req.ip,
    });

    // Set token in HTTP-only cookie if available
    if (result.token) {
      res.cookie('accessToken', result.token, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'strict',
        maxAge: 24 * 60 * 60 * 1000, // 24 hours
      });
    }

    res.json({
      success: true,
      message: 'Authentication successful',
      data: {
        user: result.user,
        token: result.token, // Also return in response body
      },
    });
  });

  /**
   * Get current user profile
   * GET /api/users/profile
   */
  getProfile = asyncHandler(async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
      throw createError.auth('Authentication required');
    }

    const result = await this.userService.getProfile(userId);

    res.json({
      success: true,
      data: {
        profile: result.profile,
      },
    });
  });

  /**
   * Update user profile
   * PUT /api/users/profile
   */
  updateProfile = asyncHandler(async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
      throw createError.auth('Authentication required');
    }

    // Validate request body
    const validationResult = UpdateProfileSchema.safeParse(req.body);
    if (!validationResult.success) {
      throw createError.validation('Invalid profile data', validationResult.error.errors);
    }

    const updateData = validationResult.data;

    // Update profile
    const result = await this.userService.updateProfile(userId, updateData);

    this.logger.info('User profile updated', {
      userId,
      updatedFields: Object.keys(updateData),
    });

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: result.user,
      },
    });
  });

  /**
   * Change user password
   * PUT /api/users/password
   */
  changePassword = asyncHandler(async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
      throw createError.auth('Authentication required');
    }

    // Validate request body
    const validationResult = ChangePasswordSchema.safeParse(req.body);
    if (!validationResult.success) {
      throw createError.validation('Invalid password data', validationResult.error.errors);
    }

    const { currentPassword, newPassword } = validationResult.data;

    // Apply rate limiting for password changes
    if (this.rateLimiter) {
      await this.rateLimiter.checkLimit(`password-change:${userId}`, 3, 3600); // 3 attempts per hour
    }

    // Change password
    const result = await this.userService.changePassword(userId, currentPassword, newPassword);

    this.logger.info('User password changed', { userId });

    res.json({
      success: true,
      message: result.message,
    });
  });

  /**
   * Verify user email
   * POST /api/users/verify-email
   */
  verifyEmail = asyncHandler(async (req, res) => {
    const userId = req.user?.id;
    const { token } = req.body;

    if (!userId) {
      throw createError.auth('Authentication required');
    }

    if (!token) {
      throw createError.validation('Verification token is required');
    }

    const result = await this.userService.verifyEmail(userId, token);

    this.logger.info('User email verified', { userId });

    res.json({
      success: true,
      message: result.message,
    });
  });

  /**
   * Delete user account
   * DELETE /api/users/account
   */
  deleteAccount = asyncHandler(async (req, res) => {
    const userId = req.user?.id;
    if (!userId) {
      throw createError.auth('Authentication required');
    }

    // Apply rate limiting for account deletion
    if (this.rateLimiter) {
      await this.rateLimiter.checkLimit(`delete-account:${userId}`, 1, 86400); // 1 attempt per day
    }

    const result = await this.userService.deleteAccount(userId);

    this.logger.info('User account deleted', { userId });

    // Clear authentication cookie
    res.clearCookie('accessToken');

    res.json({
      success: true,
      message: result.message,
    });
  });

  /**
   * List users (admin only)
   * GET /api/users
   */
  listUsers = asyncHandler(async (req, res) => {
    // Check admin permission
    if (!req.user?.permissions?.includes('admin')) {
      throw createError.forbidden('Admin access required', 'admin');
    }

    // Validate query parameters
    const validationResult = ListUsersSchema.safeParse(req.query);
    if (!validationResult.success) {
      throw createError.validation('Invalid query parameters', validationResult.error.errors);
    }

    const options = validationResult.data;

    // List users
    const result = await this.userService.listUsers(options);

    res.json({
      success: true,
      data: {
        users: result.users,
        pagination: result.pagination,
      },
    });
  });

  /**
   * Get user by ID (admin only)
   * GET /api/users/:id
   */
  getUserById = asyncHandler(async (req, res) => {
    // Check admin permission
    if (!req.user?.permissions?.includes('admin')) {
      throw createError.forbidden('Admin access required', 'admin');
    }

    const { id } = req.params;
    
    if (!id) {
      throw createError.validation('User ID is required');
    }

    const result = await this.userService.getProfile(id);

    res.json({
      success: true,
      data: {
        user: result.profile,
      },
    });
  });

  /**
   * Update user role (admin only)
   * PUT /api/users/:id/role
   */
  updateUserRole = asyncHandler(async (req, res) => {
    // Check admin permission
    if (!req.user?.permissions?.includes('admin')) {
      throw createError.forbidden('Admin access required', 'admin');
    }

    const { id } = req.params;
    const adminUserId = req.user.id;
    
    if (!id) {
      throw createError.validation('User ID is required');
    }

    // Validate request body
    const validationResult = UpdateRoleSchema.safeParse(req.body);
    if (!validationResult.success) {
      throw createError.validation('Invalid role data', validationResult.error.errors);
    }

    const { role } = validationResult.data;

    // Prevent self-role change
    if (id === adminUserId) {
      throw createError.business('Cannot change your own role', 'SELF_ROLE_CHANGE');
    }

    const result = await this.userService.updateUserRole(id, role, adminUserId);

    this.logger.info('User role updated by admin', {
      targetUserId: id,
      newRole: role,
      adminUserId,
    });

    res.json({
      success: true,
      message: result.message,
      data: {
        user: result.user,
      },
    });
  });

  /**
   * Deactivate user (admin only)
   * PUT /api/users/:id/deactivate
   */
  deactivateUser = asyncHandler(async (req, res) => {
    // Check admin permission
    if (!req.user?.permissions?.includes('admin')) {
      throw createError.forbidden('Admin access required', 'admin');
    }

    const { id } = req.params;
    const { reason } = req.body;
    const adminUserId = req.user.id;
    
    if (!id) {
      throw createError.validation('User ID is required');
    }

    if (!reason || reason.trim().length === 0) {
      throw createError.validation('Deactivation reason is required');
    }

    // Prevent self-deactivation
    if (id === adminUserId) {
      throw createError.business('Cannot deactivate your own account', 'SELF_DEACTIVATION');
    }

    const result = await this.userService.deactivateUser(id, reason.trim(), adminUserId);

    this.logger.info('User deactivated by admin', {
      targetUserId: id,
      reason,
      adminUserId,
    });

    res.json({
      success: true,
      message: result.message,
    });
  });

  /**
   * Logout user
   * POST /api/users/logout
   */
  logout = asyncHandler(async (req, res) => {
    const userId = req.user?.id;

    // Clear authentication cookie
    res.clearCookie('accessToken');

    if (userId) {
      this.logger.info('User logged out', { userId });
    }

    res.json({
      success: true,
      message: 'Logged out successfully',
    });
  });
}

module.exports = { UserController };