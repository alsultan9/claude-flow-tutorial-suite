/**
 * User Repository Implementation
 * Data access layer following Repository pattern with interface abstraction
 */

const { createError } = require('../../shared/errors');

/**
 * User Repository Interface
 * Defines the contract for user data operations
 */
class IUserRepository {
  async findById(id) {
    throw new Error('Method not implemented');
  }

  async findByEmail(email) {
    throw new Error('Method not implemented');
  }

  async findMany(options = {}) {
    throw new Error('Method not implemented');
  }

  async save(userData) {
    throw new Error('Method not implemented');
  }

  async update(id, updateData) {
    throw new Error('Method not implemented');
  }

  async delete(id) {
    throw new Error('Method not implemented');
  }

  async exists(criteria) {
    throw new Error('Method not implemented');
  }

  async count(filters = {}) {
    throw new Error('Method not implemented');
  }
}

/**
 * PostgreSQL User Repository Implementation
 */
class PostgreSQLUserRepository extends IUserRepository {
  constructor(database, logger) {
    super();
    this.db = database;
    this.logger = logger;
    this.tableName = 'users';
  }

  /**
   * Find user by ID
   * @param {string} id - User ID
   * @returns {Promise<Object|null>} User data or null
   */
  async findById(id) {
    try {
      const query = `
        SELECT * FROM ${this.tableName} 
        WHERE id = $1 AND deleted_at IS NULL
      `;
      
      const result = await this.db.query(query, [id]);
      
      if (result.rows.length === 0) {
        return null;
      }

      return this._mapDatabaseToModel(result.rows[0]);
    } catch (error) {
      this.logger.error('Error finding user by ID', { id, error: error.message });
      throw createError.database('Failed to find user by ID', error);
    }
  }

  /**
   * Find user by email
   * @param {string} email - User email
   * @returns {Promise<Object|null>} User data or null
   */
  async findByEmail(email) {
    try {
      const query = `
        SELECT * FROM ${this.tableName} 
        WHERE email = $1 AND deleted_at IS NULL
      `;
      
      const result = await this.db.query(query, [email.toLowerCase()]);
      
      if (result.rows.length === 0) {
        return null;
      }

      return this._mapDatabaseToModel(result.rows[0]);
    } catch (error) {
      this.logger.error('Error finding user by email', { email, error: error.message });
      throw createError.database('Failed to find user by email', error);
    }
  }

  /**
   * Find multiple users with filtering and pagination
   * @param {Object} options - Query options
   * @returns {Promise<Object>} Paginated results
   */
  async findMany(options = {}) {
    try {
      const {
        filters = {},
        page = 1,
        limit = 10,
        orderBy = [{ field: 'created_at', direction: 'desc' }],
      } = options;

      // Build WHERE clause
      const whereConditions = ['deleted_at IS NULL'];
      const queryParams = [];
      let paramIndex = 1;

      if (filters.role) {
        whereConditions.push(`role = $${paramIndex++}`);
        queryParams.push(filters.role);
      }

      if (filters.status) {
        whereConditions.push(`status = $${paramIndex++}`);
        queryParams.push(filters.status);
      }

      if (filters.verified !== undefined) {
        whereConditions.push(`verified = $${paramIndex++}`);
        queryParams.push(filters.verified);
      }

      if (filters.search) {
        whereConditions.push(`(name ILIKE $${paramIndex} OR email ILIKE $${paramIndex})`);
        queryParams.push(`%${filters.search}%`);
        paramIndex++;
      }

      const whereClause = whereConditions.join(' AND ');

      // Build ORDER BY clause
      const orderByClause = orderBy
        .map(({ field, direction }) => `${this._mapFieldName(field)} ${direction.toUpperCase()}`)
        .join(', ');

      // Calculate offset
      const offset = (page - 1) * limit;

      // Count query
      const countQuery = `
        SELECT COUNT(*) as total 
        FROM ${this.tableName} 
        WHERE ${whereClause}
      `;
      
      const countResult = await this.db.query(countQuery, queryParams);
      const total = parseInt(countResult.rows[0].total);

      // Data query
      const dataQuery = `
        SELECT * FROM ${this.tableName}
        WHERE ${whereClause}
        ORDER BY ${orderByClause}
        LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
      `;
      
      queryParams.push(limit, offset);
      const dataResult = await this.db.query(dataQuery, queryParams);

      return {
        data: dataResult.rows.map(row => this._mapDatabaseToModel(row)),
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      };
    } catch (error) {
      this.logger.error('Error finding multiple users', { options, error: error.message });
      throw createError.database('Failed to find users', error);
    }
  }

  /**
   * Save new user
   * @param {Object} userData - User data to save
   * @returns {Promise<Object>} Saved user data
   */
  async save(userData) {
    try {
      const query = `
        INSERT INTO ${this.tableName} (
          id, email, password, name, role, status, verified,
          profile, permissions, metadata, created_at, updated_at
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
        ) RETURNING *
      `;

      const id = userData.id || this._generateId();
      const values = [
        id,
        userData.email.toLowerCase(),
        userData.password,
        userData.name,
        userData.role || 'user',
        userData.status || 'active',
        userData.verified || false,
        JSON.stringify(userData.profile || {}),
        JSON.stringify(userData.permissions || []),
        JSON.stringify(userData.metadata || {}),
        userData.createdAt || new Date(),
        userData.updatedAt || new Date(),
      ];

      const result = await this.db.query(query, values);
      
      this.logger.info('User saved successfully', { userId: id });
      
      return this._mapDatabaseToModel(result.rows[0]);
    } catch (error) {
      if (error.code === '23505') { // Unique constraint violation
        if (error.constraint === 'users_email_unique') {
          throw createError.conflict('Email already exists', 'email', userData.email);
        }
      }
      
      this.logger.error('Error saving user', { userData: { ...userData, password: '[HIDDEN]' }, error: error.message });
      throw createError.database('Failed to save user', error);
    }
  }

  /**
   * Update existing user
   * @param {string} id - User ID
   * @param {Object} updateData - Data to update
   * @returns {Promise<Object>} Updated user data
   */
  async update(id, updateData) {
    try {
      // Build dynamic update query
      const updateFields = [];
      const queryParams = [];
      let paramIndex = 1;

      // Add updated_at automatically
      updateData.updatedAt = new Date();

      Object.entries(updateData).forEach(([key, value]) => {
        const dbField = this._mapFieldName(key);
        
        if (['profile', 'permissions', 'metadata'].includes(key)) {
          updateFields.push(`${dbField} = $${paramIndex++}`);
          queryParams.push(JSON.stringify(value));
        } else if (key === 'email') {
          updateFields.push(`${dbField} = $${paramIndex++}`);
          queryParams.push(value.toLowerCase());
        } else {
          updateFields.push(`${dbField} = $${paramIndex++}`);
          queryParams.push(value);
        }
      });

      const query = `
        UPDATE ${this.tableName} 
        SET ${updateFields.join(', ')}
        WHERE id = $${paramIndex} AND deleted_at IS NULL
        RETURNING *
      `;
      
      queryParams.push(id);
      const result = await this.db.query(query, queryParams);

      if (result.rows.length === 0) {
        throw createError.notFound('User', id);
      }

      this.logger.info('User updated successfully', { userId: id, updatedFields: Object.keys(updateData) });
      
      return this._mapDatabaseToModel(result.rows[0]);
    } catch (error) {
      if (error instanceof Error && error.name.includes('Error')) {
        throw error; // Re-throw custom errors
      }
      
      this.logger.error('Error updating user', { id, updateData, error: error.message });
      throw createError.database('Failed to update user', error);
    }
  }

  /**
   * Soft delete user
   * @param {string} id - User ID
   * @returns {Promise<boolean>} Success status
   */
  async delete(id) {
    try {
      const query = `
        UPDATE ${this.tableName} 
        SET deleted_at = $1, updated_at = $1
        WHERE id = $2 AND deleted_at IS NULL
        RETURNING id
      `;
      
      const result = await this.db.query(query, [new Date(), id]);

      if (result.rows.length === 0) {
        throw createError.notFound('User', id);
      }

      this.logger.info('User deleted successfully', { userId: id });
      
      return true;
    } catch (error) {
      if (error instanceof Error && error.name.includes('Error')) {
        throw error; // Re-throw custom errors
      }
      
      this.logger.error('Error deleting user', { id, error: error.message });
      throw createError.database('Failed to delete user', error);
    }
  }

  /**
   * Check if user exists with given criteria
   * @param {Object} criteria - Search criteria
   * @returns {Promise<boolean>} Existence status
   */
  async exists(criteria) {
    try {
      const whereConditions = ['deleted_at IS NULL'];
      const queryParams = [];
      let paramIndex = 1;

      Object.entries(criteria).forEach(([key, value]) => {
        const dbField = this._mapFieldName(key);
        whereConditions.push(`${dbField} = $${paramIndex++}`);
        queryParams.push(key === 'email' ? value.toLowerCase() : value);
      });

      const query = `
        SELECT 1 FROM ${this.tableName}
        WHERE ${whereConditions.join(' AND ')}
        LIMIT 1
      `;

      const result = await this.db.query(query, queryParams);
      
      return result.rows.length > 0;
    } catch (error) {
      this.logger.error('Error checking user existence', { criteria, error: error.message });
      throw createError.database('Failed to check user existence', error);
    }
  }

  /**
   * Count users with filters
   * @param {Object} filters - Filter criteria
   * @returns {Promise<number>} Count of users
   */
  async count(filters = {}) {
    try {
      const whereConditions = ['deleted_at IS NULL'];
      const queryParams = [];
      let paramIndex = 1;

      Object.entries(filters).forEach(([key, value]) => {
        const dbField = this._mapFieldName(key);
        whereConditions.push(`${dbField} = $${paramIndex++}`);
        queryParams.push(key === 'email' ? value.toLowerCase() : value);
      });

      const query = `
        SELECT COUNT(*) as total FROM ${this.tableName}
        WHERE ${whereConditions.join(' AND ')}
      `;

      const result = await this.db.query(query, queryParams);
      
      return parseInt(result.rows[0].total);
    } catch (error) {
      this.logger.error('Error counting users', { filters, error: error.message });
      throw createError.database('Failed to count users', error);
    }
  }

  /**
   * Map database field names to model field names
   * @private
   * @param {string} fieldName - Model field name
   * @returns {string} Database field name
   */
  _mapFieldName(fieldName) {
    const fieldMapping = {
      createdAt: 'created_at',
      updatedAt: 'updated_at',
      lastLoginAt: 'last_login_at',
      deletedAt: 'deleted_at',
    };

    return fieldMapping[fieldName] || fieldName;
  }

  /**
   * Map database row to model object
   * @private
   * @param {Object} row - Database row
   * @returns {Object} Model object
   */
  _mapDatabaseToModel(row) {
    return {
      id: row.id,
      email: row.email,
      password: row.password,
      name: row.name,
      role: row.role,
      status: row.status,
      verified: row.verified,
      profile: typeof row.profile === 'string' ? JSON.parse(row.profile) : row.profile,
      permissions: typeof row.permissions === 'string' ? JSON.parse(row.permissions) : row.permissions,
      metadata: typeof row.metadata === 'string' ? JSON.parse(row.metadata) : row.metadata,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      lastLoginAt: row.last_login_at,
    };
  }

  /**
   * Generate unique user ID
   * @private
   * @returns {string} Unique ID
   */
  _generateId() {
    return `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

/**
 * In-Memory User Repository (for testing)
 */
class InMemoryUserRepository extends IUserRepository {
  constructor(logger) {
    super();
    this.users = new Map();
    this.logger = logger;
  }

  async findById(id) {
    const user = this.users.get(id);
    return user && !user.deletedAt ? { ...user } : null;
  }

  async findByEmail(email) {
    const normalizedEmail = email.toLowerCase();
    for (const user of this.users.values()) {
      if (user.email === normalizedEmail && !user.deletedAt) {
        return { ...user };
      }
    }
    return null;
  }

  async findMany(options = {}) {
    const { filters = {}, page = 1, limit = 10 } = options;
    
    let users = Array.from(this.users.values())
      .filter(user => !user.deletedAt);

    // Apply filters
    if (filters.role) {
      users = users.filter(user => user.role === filters.role);
    }
    if (filters.status) {
      users = users.filter(user => user.status === filters.status);
    }
    if (filters.verified !== undefined) {
      users = users.filter(user => user.verified === filters.verified);
    }
    if (filters.search) {
      const search = filters.search.toLowerCase();
      users = users.filter(user => 
        user.name.toLowerCase().includes(search) || 
        user.email.toLowerCase().includes(search)
      );
    }

    const total = users.length;
    const offset = (page - 1) * limit;
    const paginatedUsers = users.slice(offset, offset + limit);

    return {
      data: paginatedUsers.map(user => ({ ...user })),
      page,
      limit,
      total,
      pages: Math.ceil(total / limit),
    };
  }

  async save(userData) {
    const id = userData.id || this._generateId();
    
    // Check for email uniqueness
    const existingUser = await this.findByEmail(userData.email);
    if (existingUser) {
      throw createError.conflict('Email already exists', 'email', userData.email);
    }

    const user = {
      ...userData,
      id,
      email: userData.email.toLowerCase(),
      createdAt: userData.createdAt || new Date(),
      updatedAt: userData.updatedAt || new Date(),
    };

    this.users.set(id, user);
    return { ...user };
  }

  async update(id, updateData) {
    const user = this.users.get(id);
    if (!user || user.deletedAt) {
      throw createError.notFound('User', id);
    }

    const updatedUser = {
      ...user,
      ...updateData,
      updatedAt: new Date(),
    };

    this.users.set(id, updatedUser);
    return { ...updatedUser };
  }

  async delete(id) {
    const user = this.users.get(id);
    if (!user || user.deletedAt) {
      throw createError.notFound('User', id);
    }

    user.deletedAt = new Date();
    user.updatedAt = new Date();
    
    return true;
  }

  async exists(criteria) {
    for (const user of this.users.values()) {
      if (user.deletedAt) continue;
      
      const matches = Object.entries(criteria).every(([key, value]) => {
        const userValue = key === 'email' ? user.email : user[key];
        const searchValue = key === 'email' ? value.toLowerCase() : value;
        return userValue === searchValue;
      });
      
      if (matches) return true;
    }
    return false;
  }

  async count(filters = {}) {
    const result = await this.findMany({ filters, page: 1, limit: Number.MAX_SAFE_INTEGER });
    return result.total;
  }

  _generateId() {
    return `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

module.exports = {
  IUserRepository,
  PostgreSQLUserRepository,
  InMemoryUserRepository,
};