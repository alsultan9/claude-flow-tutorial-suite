/**
 * User Service (Application Layer)
 * Orchestrates user-related business operations
 * Implementation follows London School TDD patterns with dependency injection
 */

const { User } = require('../../domain/user/User');
const { createError } = require('../../shared/errors');

/**
 * User Service Class
 * Handles user registration, authentication, profile management, and account operations
 */
class UserService {
  constructor(userRepository, emailService, hashingService, auditLog, tokenService = null) {
    this.userRepository = userRepository;
    this.emailService = emailService;
    this.hashingService = hashingService;
    this.auditLog = auditLog;
    this.tokenService = tokenService;
  }

  /**
   * Register a new user
   * @param {Object} userData - User registration data
   * @returns {Promise<Object>} Registration result
   */
  async register(userData) {
    // Check if email already exists
    const existingUser = await this.userRepository.findByEmail(userData.email);
    if (existingUser) {
      throw createError.conflict('Email already exists', 'email', userData.email);
    }

    // Hash password
    const hashedPassword = await this.hashingService.hash(userData.password);

    // Create user domain object
    const user = User.create({
      ...userData,
      password: hashedPassword,
      isPasswordHashed: true,
    });

    // Save user
    const savedUser = await this.userRepository.save(user.toDatabaseObject());

    // Send welcome email (non-blocking - continue if fails)
    try {
      await this.emailService.sendWelcomeEmail(
        savedUser.id,
        savedUser.email,
        savedUser.name
      );
    } catch (emailError) {
      // Log email failure but don't fail registration
      console.warn('Welcome email failed:', emailError.message);
    }

    // Log registration event
    await this.auditLog.logUserRegistration(savedUser.id);

    return {
      success: true,
      user: this._sanitizeUserForResponse(savedUser),
      message: 'User registered successfully',
    };
  }

  /**
   * Authenticate user with email and password
   * @param {string} email - User email
   * @param {string} plainPassword - Plain text password
   * @returns {Promise<Object>} Authentication result
   */
  async authenticate(email, plainPassword) {
    // Find user by email
    const userData = await this.userRepository.findByEmail(email);
    if (!userData) {
      throw createError.auth('Invalid credentials', 'INVALID_CREDENTIALS');
    }

    // Create user domain object
    const user = User.fromDatabase(userData);

    // Authenticate using domain logic
    user.authenticate(plainPassword, this.hashingService);

    // Update last login time
    await this.userRepository.update(user.id, { lastLoginAt: user.lastLoginAt });

    // Log successful login
    await this.auditLog.logUserLogin(user.id, email);

    // Generate token if token service is available
    let token = null;
    if (this.tokenService) {
      token = await this.tokenService.generateAccessToken({
        userId: user.id,
        email: user.email.value,
        role: user.role,
      });
    }

    return {
      success: true,
      user: this._sanitizeUserForResponse(user.toPublicObject()),
      token,
    };
  }

  /**
   * Get user profile by ID
   * @param {string} userId - User ID
   * @returns {Promise<Object>} Profile result
   */
  async getProfile(userId) {
    const userData = await this.userRepository.findById(userId);
    if (!userData) {
      throw createError.notFound('User', userId);
    }

    const user = User.fromDatabase(userData);

    return {
      success: true,
      profile: this._sanitizeUserForResponse(user.toPublicObject()),
    };
  }

  /**
   * Update user profile
   * @param {string} userId - User ID
   * @param {Object} updateData - Profile update data
   * @returns {Promise<Object>} Update result
   */
  async updateProfile(userId, updateData) {
    // Find existing user
    const userData = await this.userRepository.findById(userId);
    if (!userData) {
      throw createError.notFound('User', userId);
    }

    const user = User.fromDatabase(userData);

    // Handle email change separately (requires duplicate check)
    if (updateData.email && updateData.email !== user.email.value) {
      const existingUserWithEmail = await this.userRepository.findByEmail(updateData.email);
      if (existingUserWithEmail && existingUserWithEmail.id !== userId) {
        throw createError.conflict('Email already exists', 'email', updateData.email);
      }

      // Change email using domain logic
      user.changeEmail(updateData.email, this.emailService);

      // Send email change notification
      try {
        await this.emailService.sendEmailChangeNotification(userId, updateData.email);
      } catch (emailError) {
        console.warn('Email change notification failed:', emailError.message);
      }
    }

    // Update profile using domain logic
    const profileData = { ...updateData };
    delete profileData.email; // Already handled above
    delete profileData.password; // Use separate method for password changes
    
    user.updateProfile(profileData);

    // Save updated user
    const updatedUser = await this.userRepository.update(userId, user.toDatabaseObject());

    // Log profile update
    await this.auditLog.logProfileUpdate(userId, updateData);

    return {
      success: true,
      user: this._sanitizeUserForResponse(updatedUser),
    };
  }

  /**
   * Change user password
   * @param {string} userId - User ID
   * @param {string} currentPassword - Current password
   * @param {string} newPassword - New password
   * @returns {Promise<Object>} Password change result
   */
  async changePassword(userId, currentPassword, newPassword) {
    // Find and authenticate user
    const userData = await this.userRepository.findById(userId);
    if (!userData) {
      throw createError.notFound('User', userId);
    }

    const user = User.fromDatabase(userData);

    // Verify current password
    if (!this.hashingService.verify(currentPassword, user.password.value)) {
      throw createError.auth('Current password is incorrect', 'INVALID_CURRENT_PASSWORD');
    }

    // Change password using domain logic
    user.changePassword(newPassword, this.hashingService);

    // Save updated password
    await this.userRepository.update(userId, {
      password: user.password.value,
      updatedAt: user.updatedAt,
    });

    // Log password change
    await this.auditLog.logPasswordChange(userId);

    return {
      success: true,
      message: 'Password changed successfully',
    };
  }

  /**
   * Verify user email
   * @param {string} userId - User ID
   * @param {string} verificationToken - Verification token
   * @returns {Promise<Object>} Verification result
   */
  async verifyEmail(userId, verificationToken) {
    // Find user
    const userData = await this.userRepository.findById(userId);
    if (!userData) {
      throw createError.notFound('User', userId);
    }

    const user = User.fromDatabase(userData);

    // Verify using domain logic
    user.verify();

    // Save verification status
    await this.userRepository.update(userId, {
      verified: user.verified,
      updatedAt: user.updatedAt,
    });

    // Log verification
    await this.auditLog.logEmailVerification(userId);

    return {
      success: true,
      message: 'Email verified successfully',
    };
  }

  /**
   * Delete user account
   * @param {string} userId - User ID
   * @returns {Promise<Object>} Deletion result
   */
  async deleteAccount(userId) {
    // Find user
    const userData = await this.userRepository.findById(userId);
    if (!userData) {
      throw createError.notFound('User', userId);
    }

    const user = User.fromDatabase(userData);

    // Delete user
    await this.userRepository.delete(userId);

    // Send account deletion confirmation
    try {
      await this.emailService.sendAccountDeletionConfirmation(
        user.email.value,
        user.name
      );
    } catch (emailError) {
      console.warn('Account deletion confirmation email failed:', emailError.message);
    }

    // Log account deletion
    await this.auditLog.logAccountDeletion(userId);

    return {
      success: true,
      message: 'Account deleted successfully',
    };
  }

  /**
   * List users with filtering and pagination
   * @param {Object} options - Query options
   * @returns {Promise<Object>} Users list result
   */
  async listUsers(options = {}) {
    const {
      page = 1,
      limit = 10,
      role = null,
      status = null,
      verified = null,
      search = null,
    } = options;

    const filters = {};
    if (role) filters.role = role;
    if (status) filters.status = status;
    if (verified !== null) filters.verified = verified;
    if (search) filters.search = search;

    const result = await this.userRepository.findMany({
      filters,
      page,
      limit,
      orderBy: [{ field: 'createdAt', direction: 'desc' }],
    });

    return {
      success: true,
      users: result.data.map(userData => this._sanitizeUserForResponse(userData)),
      pagination: {
        page: result.page,
        limit: result.limit,
        total: result.total,
        pages: result.pages,
      },
    };
  }

  /**
   * Update user role (admin operation)
   * @param {string} userId - User ID
   * @param {string} newRole - New role
   * @param {string} adminUserId - Admin user ID performing the action
   * @returns {Promise<Object>} Role update result
   */
  async updateUserRole(userId, newRole, adminUserId) {
    // Find user
    const userData = await this.userRepository.findById(userId);
    if (!userData) {
      throw createError.notFound('User', userId);
    }

    const user = User.fromDatabase(userData);

    // Assign role using domain logic
    user.assignRole(newRole);

    // Save updated role
    await this.userRepository.update(userId, {
      role: user.role,
      permissions: user.permissions,
      updatedAt: user.updatedAt,
    });

    // Log role change
    await this.auditLog.logRoleChange(userId, newRole, adminUserId);

    return {
      success: true,
      user: this._sanitizeUserForResponse(user.toPublicObject()),
      message: 'User role updated successfully',
    };
  }

  /**
   * Deactivate user account (admin operation)
   * @param {string} userId - User ID
   * @param {string} reason - Deactivation reason
   * @param {string} adminUserId - Admin user ID performing the action
   * @returns {Promise<Object>} Deactivation result
   */
  async deactivateUser(userId, reason, adminUserId) {
    // Find user
    const userData = await this.userRepository.findById(userId);
    if (!userData) {
      throw createError.notFound('User', userId);
    }

    const user = User.fromDatabase(userData);

    // Deactivate using domain logic
    user.deactivate(reason);

    // Save updated status
    await this.userRepository.update(userId, {
      status: user.status,
      metadata: user.metadata,
      updatedAt: user.updatedAt,
    });

    // Log deactivation
    await this.auditLog.logUserDeactivation(userId, reason, adminUserId);

    return {
      success: true,
      message: 'User deactivated successfully',
    };
  }

  /**
   * Private helper method to sanitize user data for API responses
   * @private
   * @param {Object} userData - Raw user data
   * @returns {Object} Sanitized user data
   */
  _sanitizeUserForResponse(userData) {
    const sanitized = { ...userData };
    delete sanitized.password;
    return sanitized;
  }
}

module.exports = { UserService };