/**
 * User Builder (London School TDD)
 * Test data builder for consistent user object creation
 */

class UserBuilder {
  constructor() {
    this.userData = {
      id: null,
      email: 'test@example.com',
      password: 'defaultPassword123',
      name: 'Test User',
      role: 'user',
      active: true,
      verified: false,
      createdAt: new Date('2024-01-01T00:00:00.000Z'),
      updatedAt: new Date('2024-01-01T00:00:00.000Z'),
      profile: {
        firstName: 'Test',
        lastName: 'User',
        phone: null,
        address: null,
        dateOfBirth: null,
        preferences: {
          notifications: true,
          theme: 'light',
          language: 'en'
        }
      },
      permissions: ['read'],
      metadata: {}
    };
  }

  /**
   * Create a new UserBuilder instance
   * @returns {UserBuilder}
   */
  static create() {
    return new UserBuilder();
  }

  /**
   * Set user ID
   * @param {string} id - User ID
   * @returns {UserBuilder}
   */
  withId(id) {
    this.userData.id = id;
    return this;
  }

  /**
   * Set user email
   * @param {string} email - User email
   * @returns {UserBuilder}
   */
  withEmail(email) {
    this.userData.email = email;
    return this;
  }

  /**
   * Set user password
   * @param {string} password - User password
   * @returns {UserBuilder}
   */
  withPassword(password) {
    this.userData.password = password;
    return this;
  }

  /**
   * Set user name
   * @param {string} name - User full name
   * @returns {UserBuilder}
   */
  withName(name) {
    this.userData.name = name;
    // Also update profile names
    const nameParts = name.split(' ');
    this.userData.profile.firstName = nameParts[0] || 'Test';
    this.userData.profile.lastName = nameParts.slice(1).join(' ') || 'User';
    return this;
  }

  /**
   * Set user role
   * @param {string} role - User role (user, admin, moderator)
   * @returns {UserBuilder}
   */
  withRole(role) {
    this.userData.role = role;
    
    // Set appropriate permissions based on role
    const rolePermissions = {
      admin: ['read', 'write', 'delete', 'admin'],
      moderator: ['read', 'write', 'moderate'],
      user: ['read'],
      guest: []
    };
    
    this.userData.permissions = rolePermissions[role] || ['read'];
    return this;
  }

  /**
   * Set user active status
   * @param {boolean} active - Whether user is active
   * @returns {UserBuilder}
   */
  withActiveStatus(active) {
    this.userData.active = active;
    return this;
  }

  /**
   * Set user verified status
   * @param {boolean} verified - Whether user is verified
   * @returns {UserBuilder}
   */
  withVerifiedStatus(verified) {
    this.userData.verified = verified;
    return this;
  }

  /**
   * Set creation date
   * @param {Date|string} date - Creation date
   * @returns {UserBuilder}
   */
  withCreatedAt(date) {
    this.userData.createdAt = new Date(date);
    return this;
  }

  /**
   * Set update date
   * @param {Date|string} date - Update date
   * @returns {UserBuilder}
   */
  withUpdatedAt(date) {
    this.userData.updatedAt = new Date(date);
    return this;
  }

  /**
   * Set user profile data
   * @param {Object} profile - Profile data
   * @returns {UserBuilder}
   */
  withProfile(profile) {
    this.userData.profile = { ...this.userData.profile, ...profile };
    return this;
  }

  /**
   * Set user phone number
   * @param {string} phone - Phone number
   * @returns {UserBuilder}
   */
  withPhone(phone) {
    this.userData.profile.phone = phone;
    return this;
  }

  /**
   * Set user address
   * @param {Object} address - Address object
   * @returns {UserBuilder}
   */
  withAddress(address) {
    this.userData.profile.address = address;
    return this;
  }

  /**
   * Set date of birth
   * @param {Date|string} dateOfBirth - Date of birth
   * @returns {UserBuilder}
   */
  withDateOfBirth(dateOfBirth) {
    this.userData.profile.dateOfBirth = new Date(dateOfBirth);
    return this;
  }

  /**
   * Set user preferences
   * @param {Object} preferences - User preferences
   * @returns {UserBuilder}
   */
  withPreferences(preferences) {
    this.userData.profile.preferences = { 
      ...this.userData.profile.preferences, 
      ...preferences 
    };
    return this;
  }

  /**
   * Set user permissions
   * @param {Array<string>} permissions - Array of permissions
   * @returns {UserBuilder}
   */
  withPermissions(permissions) {
    this.userData.permissions = [...permissions];
    return this;
  }

  /**
   * Add permission to user
   * @param {string} permission - Permission to add
   * @returns {UserBuilder}
   */
  addPermission(permission) {
    if (!this.userData.permissions.includes(permission)) {
      this.userData.permissions.push(permission);
    }
    return this;
  }

  /**
   * Set metadata
   * @param {Object} metadata - Metadata object
   * @returns {UserBuilder}
   */
  withMetadata(metadata) {
    this.userData.metadata = { ...this.userData.metadata, ...metadata };
    return this;
  }

  /**
   * Add metadata key-value pair
   * @param {string} key - Metadata key
   * @param {any} value - Metadata value
   * @returns {UserBuilder}
   */
  addMetadata(key, value) {
    this.userData.metadata[key] = value;
    return this;
  }

  /**
   * Create admin user preset
   * @returns {UserBuilder}
   */
  asAdmin() {
    return this
      .withRole('admin')
      .withName('Admin User')
      .withEmail('admin@example.com')
      .withVerifiedStatus(true)
      .withActiveStatus(true);
  }

  /**
   * Create moderator user preset
   * @returns {UserBuilder}
   */
  asModerator() {
    return this
      .withRole('moderator')
      .withName('Moderator User')
      .withEmail('moderator@example.com')
      .withVerifiedStatus(true)
      .withActiveStatus(true);
  }

  /**
   * Create guest user preset
   * @returns {UserBuilder}
   */
  asGuest() {
    return this
      .withRole('guest')
      .withName('Guest User')
      .withEmail('guest@example.com')
      .withVerifiedStatus(false)
      .withActiveStatus(true);
  }

  /**
   * Create inactive user preset
   * @returns {UserBuilder}
   */
  asInactive() {
    return this
      .withActiveStatus(false)
      .withName('Inactive User')
      .withEmail('inactive@example.com');
  }

  /**
   * Create unverified user preset
   * @returns {UserBuilder}
   */
  asUnverified() {
    return this
      .withVerifiedStatus(false)
      .withName('Unverified User')
      .withEmail('unverified@example.com');
  }

  /**
   * Create user with complete profile
   * @returns {UserBuilder}
   */
  withCompleteProfile() {
    return this
      .withPhone('555-0123')
      .withAddress({
        street: '123 Test St',
        city: 'Test City',
        state: 'TS',
        zipCode: '12345',
        country: 'US'
      })
      .withDateOfBirth('1990-01-01')
      .withPreferences({
        notifications: true,
        theme: 'dark',
        language: 'en',
        timezone: 'America/New_York'
      });
  }

  /**
   * Create user for specific test scenario
   * @param {string} scenario - Test scenario name
   * @returns {UserBuilder}
   */
  forScenario(scenario) {
    const scenarios = {
      'registration': () => this
        .withId(null)
        .withVerifiedStatus(false)
        .withCreatedAt(new Date()),
      
      'authentication': () => this
        .withId('auth-user-123')
        .withVerifiedStatus(true)
        .withActiveStatus(true)
        .withPassword('hashedPassword123'),
      
      'profile-update': () => this
        .withId('profile-user-456')
        .withVerifiedStatus(true)
        .withCompleteProfile(),
      
      'account-deletion': () => this
        .withId('delete-user-789')
        .withActiveStatus(false)
        .withMetadata({ deletionRequested: new Date() }),
      
      'password-reset': () => this
        .withId('reset-user-101')
        .withVerifiedStatus(true)
        .addMetadata('resetToken', 'reset-token-123')
        .addMetadata('resetExpiry', new Date(Date.now() + 3600000))
    };

    const scenarioBuilder = scenarios[scenario];
    if (scenarioBuilder) {
      scenarioBuilder.call(this);
    }
    
    return this;
  }

  /**
   * Build user object without sensitive data (for API responses)
   * @returns {Object} User object without password and sensitive fields
   */
  buildPublic() {
    const user = this.build();
    const { password, ...publicUser } = user;
    return publicUser;
  }

  /**
   * Build user object for database storage
   * @returns {Object} User object optimized for database
   */
  buildForDatabase() {
    const user = this.build();
    // Ensure required fields for database
    if (!user.id) {
      user.id = `user-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    }
    return user;
  }

  /**
   * Build array of users
   * @param {number} count - Number of users to create
   * @param {Function} modifier - Optional modifier function for each user
   * @returns {Array<Object>} Array of user objects
   */
  buildMany(count, modifier) {
    const users = [];
    for (let i = 0; i < count; i++) {
      const builder = UserBuilder.create()
        .withId(`user-${i + 1}`)
        .withEmail(`user${i + 1}@example.com`)
        .withName(`User ${i + 1}`);
      
      if (modifier) {
        modifier(builder, i);
      }
      
      users.push(builder.build());
    }
    return users;
  }

  /**
   * Build the final user object
   * @returns {Object} Complete user object
   */
  build() {
    // Deep clone to avoid mutations affecting subsequent builds
    return JSON.parse(JSON.stringify(this.userData));
  }

  /**
   * Reset builder to default state
   * @returns {UserBuilder}
   */
  reset() {
    return UserBuilder.create();
  }

  /**
   * Clone current builder state
   * @returns {UserBuilder}
   */
  clone() {
    const newBuilder = new UserBuilder();
    newBuilder.userData = JSON.parse(JSON.stringify(this.userData));
    return newBuilder;
  }

  /**
   * Validate built user object
   * @returns {Object} Validation result
   */
  validate() {
    const user = this.build();
    const errors = [];

    if (!user.email || !user.email.includes('@')) {
      errors.push('Invalid email format');
    }

    if (!user.name || user.name.trim().length === 0) {
      errors.push('Name is required');
    }

    if (!user.password || user.password.length < 6) {
      errors.push('Password must be at least 6 characters');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
}

// Export both the class and convenience factory
module.exports = { 
  UserBuilder,
  createUser: (options = {}) => {
    const builder = UserBuilder.create();
    Object.entries(options).forEach(([key, value]) => {
      const methodName = `with${key.charAt(0).toUpperCase()}${key.slice(1)}`;
      if (typeof builder[methodName] === 'function') {
        builder[methodName](value);
      }
    });
    return builder.build();
  }
};