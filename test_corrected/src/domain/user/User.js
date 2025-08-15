/**
 * User Domain Model
 * Rich domain model with business logic and invariants
 */

const { createError } = require('../../shared/errors');

/**
 * User Value Objects
 */
class Email {
  constructor(value) {
    if (!this.isValid(value)) {
      throw createError.validation('Invalid email format', [], 'email');
    }
    this.value = value.toLowerCase().trim();
  }

  isValid(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  toString() {
    return this.value;
  }

  equals(other) {
    return other instanceof Email && this.value === other.value;
  }
}

class Password {
  constructor(value, isHashed = false) {
    if (!isHashed && !this.isValidPlainPassword(value)) {
      throw createError.validation(
        'Password must be at least 8 characters long and contain uppercase, lowercase, number, and special character',
        [],
        'password'
      );
    }
    this.value = value;
    this.isHashed = isHashed;
  }

  isValidPlainPassword(password) {
    if (!password || password.length < 8) return false;
    
    const hasUpperCase = /[A-Z]/.test(password);
    const hasLowerCase = /[a-z]/.test(password);
    const hasNumbers = /\d/.test(password);
    const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(password);
    
    return hasUpperCase && hasLowerCase && hasNumbers && hasSpecial;
  }

  toString() {
    return this.value;
  }
}

class UserProfile {
  constructor(data = {}) {
    this.firstName = data.firstName || null;
    this.lastName = data.lastName || null;
    this.phone = data.phone || null;
    this.address = data.address || null;
    this.dateOfBirth = data.dateOfBirth ? new Date(data.dateOfBirth) : null;
    this.preferences = {
      notifications: true,
      theme: 'light',
      language: 'en',
      ...data.preferences,
    };
  }

  getFullName() {
    if (this.firstName && this.lastName) {
      return `${this.firstName} ${this.lastName}`;
    }
    return this.firstName || this.lastName || null;
  }

  update(data) {
    return new UserProfile({
      ...this.toObject(),
      ...data,
      preferences: {
        ...this.preferences,
        ...data.preferences,
      },
    });
  }

  toObject() {
    return {
      firstName: this.firstName,
      lastName: this.lastName,
      phone: this.phone,
      address: this.address,
      dateOfBirth: this.dateOfBirth,
      preferences: { ...this.preferences },
    };
  }
}

/**
 * User Aggregate Root
 */
class User {
  constructor(data) {
    this.id = data.id || null;
    this.email = new Email(data.email);
    this.password = new Password(data.password, data.isPasswordHashed || false);
    this.name = data.name || this.email.value.split('@')[0];
    this.role = data.role || 'user';
    this.status = data.status || 'active';
    this.verified = data.verified || false;
    this.profile = new UserProfile(data.profile || {});
    this.permissions = data.permissions || this.getDefaultPermissions();
    this.metadata = data.metadata || {};
    this.createdAt = data.createdAt ? new Date(data.createdAt) : new Date();
    this.updatedAt = data.updatedAt ? new Date(data.updatedAt) : new Date();
    this.lastLoginAt = data.lastLoginAt ? new Date(data.lastLoginAt) : null;

    // Domain Events
    this.domainEvents = [];
    
    // Business Rules Validation
    this.validate();
  }

  /**
   * Factory Methods
   */
  static create(data) {
    const user = new User(data);
    user.addDomainEvent('user.created', {
      userId: user.id,
      email: user.email.value,
      role: user.role,
    });
    return user;
  }

  static fromDatabase(data) {
    return new User({
      ...data,
      isPasswordHashed: true,
    });
  }

  /**
   * Business Logic Methods
   */
  authenticate(plainPassword, passwordService) {
    if (this.status !== 'active') {
      throw createError.auth('Account is not active', 'ACCOUNT_INACTIVE');
    }

    if (!this.verified) {
      throw createError.auth('Account not verified', 'ACCOUNT_NOT_VERIFIED');
    }

    if (!passwordService.verify(plainPassword, this.password.value)) {
      this.addDomainEvent('user.authentication_failed', {
        userId: this.id,
        email: this.email.value,
        timestamp: new Date(),
      });
      throw createError.auth('Invalid credentials', 'INVALID_CREDENTIALS');
    }

    this.lastLoginAt = new Date();
    this.updatedAt = new Date();
    
    this.addDomainEvent('user.authenticated', {
      userId: this.id,
      email: this.email.value,
      lastLoginAt: this.lastLoginAt,
    });

    return true;
  }

  updateProfile(profileData) {
    const oldProfile = this.profile.toObject();
    this.profile = this.profile.update(profileData);
    this.updatedAt = new Date();

    this.addDomainEvent('user.profile_updated', {
      userId: this.id,
      changes: this.getProfileChanges(oldProfile, this.profile.toObject()),
    });

    return this;
  }

  changeEmail(newEmail, emailService) {
    const oldEmail = this.email.value;
    this.email = new Email(newEmail);
    this.verified = false; // Re-verification required
    this.updatedAt = new Date();

    this.addDomainEvent('user.email_changed', {
      userId: this.id,
      oldEmail,
      newEmail: this.email.value,
      requiresVerification: true,
    });

    return this;
  }

  changePassword(newPlainPassword, passwordService) {
    const newPassword = new Password(newPlainPassword);
    const hashedPassword = passwordService.hash(newPassword.value);
    this.password = new Password(hashedPassword, true);
    this.updatedAt = new Date();

    this.addDomainEvent('user.password_changed', {
      userId: this.id,
      timestamp: new Date(),
    });

    return this;
  }

  verify() {
    if (this.verified) {
      throw createError.business('User is already verified', 'ALREADY_VERIFIED');
    }

    this.verified = true;
    this.updatedAt = new Date();

    this.addDomainEvent('user.verified', {
      userId: this.id,
      email: this.email.value,
      verifiedAt: new Date(),
    });

    return this;
  }

  activate() {
    this.status = 'active';
    this.updatedAt = new Date();

    this.addDomainEvent('user.activated', {
      userId: this.id,
      activatedAt: new Date(),
    });

    return this;
  }

  deactivate(reason = null) {
    this.status = 'inactive';
    this.updatedAt = new Date();
    
    if (reason) {
      this.metadata.deactivationReason = reason;
    }

    this.addDomainEvent('user.deactivated', {
      userId: this.id,
      reason,
      deactivatedAt: new Date(),
    });

    return this;
  }

  assignRole(role) {
    const oldRole = this.role;
    this.role = role;
    this.permissions = this.getDefaultPermissions();
    this.updatedAt = new Date();

    this.addDomainEvent('user.role_changed', {
      userId: this.id,
      oldRole,
      newRole: role,
      permissions: this.permissions,
    });

    return this;
  }

  grantPermission(permission) {
    if (!this.permissions.includes(permission)) {
      this.permissions.push(permission);
      this.updatedAt = new Date();

      this.addDomainEvent('user.permission_granted', {
        userId: this.id,
        permission,
        grantedAt: new Date(),
      });
    }
    return this;
  }

  revokePermission(permission) {
    const index = this.permissions.indexOf(permission);
    if (index > -1) {
      this.permissions.splice(index, 1);
      this.updatedAt = new Date();

      this.addDomainEvent('user.permission_revoked', {
        userId: this.id,
        permission,
        revokedAt: new Date(),
      });
    }
    return this;
  }

  hasPermission(permission) {
    return this.permissions.includes(permission);
  }

  canPerformAction(action) {
    const actionPermissions = {
      'read_profile': ['read'],
      'update_profile': ['write'],
      'delete_account': ['delete'],
      'manage_users': ['admin'],
      'moderate_content': ['moderate', 'admin'],
    };

    const requiredPermissions = actionPermissions[action] || [];
    return requiredPermissions.some(perm => this.hasPermission(perm));
  }

  /**
   * Query Methods
   */
  isActive() {
    return this.status === 'active';
  }

  isVerified() {
    return this.verified;
  }

  isAdmin() {
    return this.role === 'admin';
  }

  isModerator() {
    return this.role === 'moderator' || this.role === 'admin';
  }

  getAge() {
    if (!this.profile.dateOfBirth) return null;
    const today = new Date();
    const birthDate = new Date(this.profile.dateOfBirth);
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    
    return age;
  }

  getDaysSinceRegistration() {
    const today = new Date();
    const diffTime = Math.abs(today - this.createdAt);
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }

  /**
   * Serialization Methods
   */
  toPublicObject() {
    return {
      id: this.id,
      email: this.email.value,
      name: this.name,
      role: this.role,
      status: this.status,
      verified: this.verified,
      profile: this.profile.toObject(),
      permissions: [...this.permissions],
      createdAt: this.createdAt.toISOString(),
      updatedAt: this.updatedAt.toISOString(),
      lastLoginAt: this.lastLoginAt?.toISOString() || null,
    };
  }

  toDatabaseObject() {
    return {
      id: this.id,
      email: this.email.value,
      password: this.password.value,
      name: this.name,
      role: this.role,
      status: this.status,
      verified: this.verified,
      profile: this.profile.toObject(),
      permissions: [...this.permissions],
      metadata: { ...this.metadata },
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      lastLoginAt: this.lastLoginAt,
    };
  }

  /**
   * Private Helper Methods
   */
  validate() {
    if (!this.email || !this.email.value) {
      throw createError.validation('Email is required', [], 'email');
    }

    if (!this.password || !this.password.value) {
      throw createError.validation('Password is required', [], 'password');
    }

    const validRoles = ['user', 'moderator', 'admin', 'guest'];
    if (!validRoles.includes(this.role)) {
      throw createError.validation('Invalid role', [], 'role');
    }

    const validStatuses = ['active', 'inactive', 'suspended', 'pending'];
    if (!validStatuses.includes(this.status)) {
      throw createError.validation('Invalid status', [], 'status');
    }
  }

  getDefaultPermissions() {
    const rolePermissions = {
      admin: ['read', 'write', 'delete', 'admin', 'moderate'],
      moderator: ['read', 'write', 'moderate'],
      user: ['read', 'write'],
      guest: ['read'],
    };

    return rolePermissions[this.role] || ['read'];
  }

  getProfileChanges(oldProfile, newProfile) {
    const changes = {};
    
    Object.keys(newProfile).forEach(key => {
      if (JSON.stringify(oldProfile[key]) !== JSON.stringify(newProfile[key])) {
        changes[key] = {
          from: oldProfile[key],
          to: newProfile[key],
        };
      }
    });
    
    return changes;
  }

  addDomainEvent(type, data) {
    this.domainEvents.push({
      type,
      data,
      timestamp: new Date().toISOString(),
      aggregateId: this.id,
      aggregateType: 'User',
    });
  }

  clearDomainEvents() {
    const events = [...this.domainEvents];
    this.domainEvents = [];
    return events;
  }
}

module.exports = {
  User,
  Email,
  Password,
  UserProfile,
};