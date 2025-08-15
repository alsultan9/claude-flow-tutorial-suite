/**
 * User Repository Mock Factory (London School TDD)
 * Centralized mock creation for consistent repository behavior
 */

class UserRepositoryMockFactory {
  /**
   * Create a basic user repository mock with all methods
   * @param {Object} overrides - Method overrides
   * @returns {Object} Mock user repository
   */
  static create(overrides = {}) {
    const defaultMock = {
      // Core CRUD operations
      findById: jest.fn(),
      findByEmail: jest.fn(),
      findAll: jest.fn(),
      save: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      
      // Query operations
      findByRole: jest.fn(),
      findActiveUsers: jest.fn(),
      findUsersByDateRange: jest.fn(),
      search: jest.fn(),
      
      // Relationship operations
      findUserWithOrders: jest.fn(),
      findUserWithProfile: jest.fn(),
      
      // Aggregate operations
      count: jest.fn(),
      exists: jest.fn(),
      
      // Transaction support
      beginTransaction: jest.fn(),
      commit: jest.fn(),
      rollback: jest.fn(),
      
      // Batch operations
      bulkInsert: jest.fn(),
      bulkUpdate: jest.fn(),
      bulkDelete: jest.fn(),
      
      ...overrides
    };
    
    return defaultMock;
  }

  /**
   * Create mock configured for successful user creation
   * @param {Object} savedUser - User to return from save
   * @returns {Object} Configured mock
   */
  static createWithSuccessfulSave(savedUser) {
    return this.create({
      findByEmail: jest.fn().mockResolvedValue(null), // Email available
      save: jest.fn().mockResolvedValue(savedUser),
      exists: jest.fn().mockResolvedValue(false)
    });
  }

  /**
   * Create mock configured for existing user scenarios
   * @param {Object} existingUser - Existing user to return
   * @returns {Object} Configured mock
   */
  static createWithExistingUser(existingUser) {
    return this.create({
      findByEmail: jest.fn().mockResolvedValue(existingUser),
      findById: jest.fn().mockResolvedValue(existingUser),
      exists: jest.fn().mockResolvedValue(true),
      save: jest.fn().mockRejectedValue(new Error('Email already exists'))
    });
  }

  /**
   * Create mock configured for user not found scenarios
   * @returns {Object} Configured mock
   */
  static createWithNotFound() {
    return this.create({
      findById: jest.fn().mockResolvedValue(null),
      findByEmail: jest.fn().mockResolvedValue(null),
      exists: jest.fn().mockResolvedValue(false),
      update: jest.fn().mockRejectedValue(new Error('User not found')),
      delete: jest.fn().mockRejectedValue(new Error('User not found'))
    });
  }

  /**
   * Create mock configured for successful updates
   * @param {Object} updatedUser - Updated user to return
   * @returns {Object} Configured mock
   */
  static createWithSuccessfulUpdate(updatedUser) {
    return this.create({
      findById: jest.fn().mockResolvedValue({ ...updatedUser, name: 'Original Name' }),
      update: jest.fn().mockResolvedValue(updatedUser),
      exists: jest.fn().mockResolvedValue(true)
    });
  }

  /**
   * Create mock configured for successful deletion
   * @param {Object} userToDelete - User that will be deleted
   * @returns {Object} Configured mock
   */
  static createWithSuccessfulDeletion(userToDelete) {
    return this.create({
      findById: jest.fn().mockResolvedValue(userToDelete),
      delete: jest.fn().mockResolvedValue(true),
      exists: jest.fn()
        .mockResolvedValueOnce(true)  // Exists before deletion
        .mockResolvedValue(false)     // Doesn't exist after deletion
    });
  }

  /**
   * Create mock configured for database errors
   * @param {string} errorMessage - Error message to throw
   * @returns {Object} Configured mock
   */
  static createWithDatabaseError(errorMessage = 'Database connection failed') {
    const error = new Error(errorMessage);
    return this.create({
      findById: jest.fn().mockRejectedValue(error),
      findByEmail: jest.fn().mockRejectedValue(error),
      save: jest.fn().mockRejectedValue(error),
      update: jest.fn().mockRejectedValue(error),
      delete: jest.fn().mockRejectedValue(error)
    });
  }

  /**
   * Create mock configured for query scenarios
   * @param {Array} users - Users to return from queries
   * @returns {Object} Configured mock
   */
  static createWithQueryResults(users) {
    return this.create({
      findAll: jest.fn().mockResolvedValue(users),
      findActiveUsers: jest.fn().mockResolvedValue(users.filter(u => u.active)),
      search: jest.fn().mockResolvedValue(users),
      count: jest.fn().mockResolvedValue(users.length),
      findByRole: jest.fn().mockImplementation((role) => 
        Promise.resolve(users.filter(u => u.role === role))
      )
    });
  }

  /**
   * Create mock configured for pagination scenarios
   * @param {Array} allUsers - All available users
   * @param {number} pageSize - Items per page
   * @returns {Object} Configured mock
   */
  static createWithPagination(allUsers, pageSize = 10) {
    return this.create({
      findAll: jest.fn().mockImplementation(({ page = 1, limit = pageSize } = {}) => {
        const startIndex = (page - 1) * limit;
        const endIndex = startIndex + limit;
        return Promise.resolve({
          users: allUsers.slice(startIndex, endIndex),
          total: allUsers.length,
          page,
          limit,
          totalPages: Math.ceil(allUsers.length / limit)
        });
      }),
      count: jest.fn().mockResolvedValue(allUsers.length)
    });
  }

  /**
   * Create mock configured for relationship loading
   * @param {Object} userWithRelations - User with loaded relationships
   * @returns {Object} Configured mock
   */
  static createWithRelationships(userWithRelations) {
    return this.create({
      findById: jest.fn().mockResolvedValue(userWithRelations),
      findUserWithOrders: jest.fn().mockResolvedValue(userWithRelations),
      findUserWithProfile: jest.fn().mockResolvedValue(userWithRelations)
    });
  }

  /**
   * Create mock configured for transaction scenarios
   * @param {boolean} shouldSucceed - Whether transaction should succeed
   * @returns {Object} Configured mock
   */
  static createWithTransactionSupport(shouldSucceed = true) {
    const transactionMock = {
      commit: jest.fn().mockResolvedValue(true),
      rollback: jest.fn().mockResolvedValue(true),
      isActive: true
    };

    return this.create({
      beginTransaction: jest.fn().mockResolvedValue(transactionMock),
      save: jest.fn().mockImplementation(async (user) => {
        if (!shouldSucceed) {
          throw new Error('Transaction failed');
        }
        return { ...user, id: 'txn-user-123' };
      }),
      commit: jest.fn().mockResolvedValue(true),
      rollback: jest.fn().mockResolvedValue(true)
    });
  }

  /**
   * Create mock configured for bulk operations
   * @param {number} expectedCount - Expected number of affected records
   * @returns {Object} Configured mock
   */
  static createWithBulkOperations(expectedCount) {
    return this.create({
      bulkInsert: jest.fn().mockResolvedValue({
        insertedCount: expectedCount,
        insertedIds: Array.from({ length: expectedCount }, (_, i) => `bulk-${i + 1}`)
      }),
      bulkUpdate: jest.fn().mockResolvedValue({
        modifiedCount: expectedCount
      }),
      bulkDelete: jest.fn().mockResolvedValue({
        deletedCount: expectedCount
      })
    });
  }

  /**
   * Create mock configured for performance testing
   * @param {number} delay - Artificial delay in ms
   * @returns {Object} Configured mock
   */
  static createWithPerformanceDelay(delay = 100) {
    const delayedResolve = (value) => 
      new Promise(resolve => setTimeout(() => resolve(value), delay));

    return this.create({
      findById: jest.fn().mockImplementation(id => 
        delayedResolve({ id, email: `user${id}@example.com` })
      ),
      save: jest.fn().mockImplementation(user => 
        delayedResolve({ ...user, id: `delayed-${Date.now()}` })
      )
    });
  }

  /**
   * Create mock configured for validation scenarios
   * @param {Object} validationRules - Validation rules to apply
   * @returns {Object} Configured mock
   */
  static createWithValidation(validationRules) {
    const validateUser = (user) => {
      if (validationRules.email && !user.email?.includes('@')) {
        throw new Error('Invalid email format');
      }
      if (validationRules.minNameLength && user.name?.length < validationRules.minNameLength) {
        throw new Error(`Name must be at least ${validationRules.minNameLength} characters`);
      }
      return true;
    };

    return this.create({
      save: jest.fn().mockImplementation(async (user) => {
        validateUser(user);
        return { ...user, id: `validated-${Date.now()}` };
      }),
      update: jest.fn().mockImplementation(async (id, updates) => {
        validateUser(updates);
        return { id, ...updates };
      })
    });
  }

  /**
   * Create mock that tracks interaction history
   * @returns {Object} Mock with interaction tracking
   */
  static createWithInteractionTracking() {
    const interactions = [];
    
    const trackInteraction = (method, args) => {
      interactions.push({
        method,
        args: [...args],
        timestamp: Date.now()
      });
    };

    const mock = this.create();
    
    // Wrap all methods to track interactions
    Object.keys(mock).forEach(method => {
      const originalMethod = mock[method];
      mock[method] = jest.fn((...args) => {
        trackInteraction(method, args);
        return originalMethod.apply(mock, args);
      });
    });

    // Add helper methods
    mock.getInteractionHistory = () => [...interactions];
    mock.clearInteractionHistory = () => interactions.splice(0);
    mock.getLastInteraction = () => interactions[interactions.length - 1];

    return mock;
  }

  /**
   * Reset all mocks in a repository mock
   * @param {Object} mockRepository - Repository mock to reset
   */
  static reset(mockRepository) {
    Object.values(mockRepository).forEach(method => {
      if (jest.isMockFunction(method)) {
        method.mockReset();
      }
    });
  }

  /**
   * Verify contract compliance for a mock
   * @param {Object} mockRepository - Repository mock to verify
   * @param {Object} expectedContract - Expected contract definition
   */
  static verifyContract(mockRepository, expectedContract) {
    const contractMethods = Object.keys(expectedContract);
    const mockMethods = Object.keys(mockRepository);

    // Check all contract methods are implemented
    contractMethods.forEach(method => {
      if (!mockMethods.includes(method)) {
        throw new Error(`Mock missing contract method: ${method}`);
      }
      
      if (!jest.isMockFunction(mockRepository[method])) {
        throw new Error(`Mock method ${method} is not a jest function`);
      }
    });

    return true;
  }
}

module.exports = { UserRepositoryMockFactory };