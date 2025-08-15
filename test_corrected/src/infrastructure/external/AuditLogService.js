/**
 * Audit Log Service Implementation
 * Tracks and logs all important system events for security and compliance
 */

const { createError } = require('../../shared/errors');

/**
 * Audit Log Service Interface
 */
class IAuditLogService {
  async logUserRegistration(userId) {
    throw new Error('Method not implemented');
  }

  async logUserLogin(userId, email) {
    throw new Error('Method not implemented');
  }

  async logUserLogout(userId) {
    throw new Error('Method not implemented');
  }

  async logProfileUpdate(userId, changes) {
    throw new Error('Method not implemented');
  }

  async logPasswordChange(userId) {
    throw new Error('Method not implemented');
  }

  async logEmailVerification(userId) {
    throw new Error('Method not implemented');
  }

  async logAccountDeletion(userId) {
    throw new Error('Method not implemented');
  }

  async logRoleChange(userId, newRole, adminUserId) {
    throw new Error('Method not implemented');
  }

  async logUserDeactivation(userId, reason, adminUserId) {
    throw new Error('Method not implemented');
  }

  async getAuditLogs(criteria) {
    throw new Error('Method not implemented');
  }
}

/**
 * Database Audit Log Service Implementation
 */
class DatabaseAuditLogService extends IAuditLogService {
  constructor(database, logger) {
    this.db = database;
    this.logger = logger;
    this.tableName = 'audit_logs';
  }

  async logUserRegistration(userId) {
    return this._logEvent('USER_REGISTERED', userId, {
      action: 'User account created',
    });
  }

  async logUserLogin(userId, email) {
    return this._logEvent('USER_LOGIN', userId, {
      action: 'User logged in',
      email,
    });
  }

  async logUserLogout(userId) {
    return this._logEvent('USER_LOGOUT', userId, {
      action: 'User logged out',
    });
  }

  async logProfileUpdate(userId, changes) {
    return this._logEvent('PROFILE_UPDATED', userId, {
      action: 'User profile updated',
      changes: Object.keys(changes),
      changedFields: changes,
    });
  }

  async logPasswordChange(userId) {
    return this._logEvent('PASSWORD_CHANGED', userId, {
      action: 'Password changed',
    });
  }

  async logEmailVerification(userId) {
    return this._logEvent('EMAIL_VERIFIED', userId, {
      action: 'Email address verified',
    });
  }

  async logAccountDeletion(userId) {
    return this._logEvent('ACCOUNT_DELETED', userId, {
      action: 'User account deleted',
    });
  }

  async logRoleChange(userId, newRole, adminUserId) {
    return this._logEvent('ROLE_CHANGED', userId, {
      action: 'User role changed',
      newRole,
      adminUserId,
    });
  }

  async logUserDeactivation(userId, reason, adminUserId) {
    return this._logEvent('USER_DEACTIVATED', userId, {
      action: 'User account deactivated',
      reason,
      adminUserId,
    });
  }

  async logSecurityEvent(eventType, userId, details = {}) {
    return this._logEvent(eventType, userId, {
      action: 'Security event',
      eventType,
      ...details,
    });
  }

  async logSystemEvent(eventType, details = {}) {
    return this._logEvent(eventType, null, {
      action: 'System event',
      eventType,
      ...details,
    });
  }

  async getAuditLogs(criteria = {}) {
    try {
      const {
        userId = null,
        eventType = null,
        startDate = null,
        endDate = null,
        page = 1,
        limit = 50,
      } = criteria;

      const whereConditions = [];
      const queryParams = [];
      let paramIndex = 1;

      if (userId) {
        whereConditions.push(`user_id = $${paramIndex++}`);
        queryParams.push(userId);
      }

      if (eventType) {
        whereConditions.push(`event_type = $${paramIndex++}`);
        queryParams.push(eventType);
      }

      if (startDate) {
        whereConditions.push(`created_at >= $${paramIndex++}`);
        queryParams.push(new Date(startDate));
      }

      if (endDate) {
        whereConditions.push(`created_at <= $${paramIndex++}`);
        queryParams.push(new Date(endDate));
      }

      const whereClause = whereConditions.length > 0 
        ? `WHERE ${whereConditions.join(' AND ')}` 
        : '';

      const offset = (page - 1) * limit;

      // Get total count
      const countQuery = `
        SELECT COUNT(*) as total 
        FROM ${this.tableName} 
        ${whereClause}
      `;
      const countResult = await this.db.query(countQuery, queryParams);
      const total = parseInt(countResult.rows[0].total);

      // Get audit logs
      const dataQuery = `
        SELECT * FROM ${this.tableName}
        ${whereClause}
        ORDER BY created_at DESC
        LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
      `;
      queryParams.push(limit, offset);

      const result = await this.db.query(dataQuery, queryParams);

      return {
        logs: result.rows.map(row => this._mapDatabaseToModel(row)),
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit),
        },
      };
    } catch (error) {
      this.logger?.error('Error retrieving audit logs', { criteria, error: error.message });
      throw createError.database('Failed to retrieve audit logs', error);
    }
  }

  async _logEvent(eventType, userId = null, details = {}) {
    try {
      const query = `
        INSERT INTO ${this.tableName} (
          id, event_type, user_id, details, ip_address, user_agent, created_at
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7
        ) RETURNING *
      `;

      const id = this._generateId();
      const values = [
        id,
        eventType,
        userId,
        JSON.stringify(details),
        details.ipAddress || null,
        details.userAgent || null,
        new Date(),
      ];

      const result = await this.db.query(query, values);

      this.logger?.info('Audit log entry created', {
        id,
        eventType,
        userId,
        action: details.action,
      });

      return this._mapDatabaseToModel(result.rows[0]);
    } catch (error) {
      this.logger?.error('Error creating audit log entry', {
        eventType,
        userId,
        error: error.message,
      });

      // Don't throw error for audit logging failures to avoid breaking main operations
      // Instead, log the error and continue
      return null;
    }
  }

  _mapDatabaseToModel(row) {
    return {
      id: row.id,
      eventType: row.event_type,
      userId: row.user_id,
      details: typeof row.details === 'string' ? JSON.parse(row.details) : row.details,
      ipAddress: row.ip_address,
      userAgent: row.user_agent,
      createdAt: row.created_at,
    };
  }

  _generateId() {
    return `audit_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

/**
 * File-based Audit Log Service (for development/testing)
 */
class FileAuditLogService extends IAuditLogService {
  constructor(logFilePath, logger) {
    this.logFilePath = logFilePath;
    this.logger = logger;
    this.fs = require('fs').promises;
    this.path = require('path');
  }

  async logUserRegistration(userId) {
    return this._writeLogEntry('USER_REGISTERED', userId, {
      action: 'User account created',
    });
  }

  async logUserLogin(userId, email) {
    return this._writeLogEntry('USER_LOGIN', userId, {
      action: 'User logged in',
      email,
    });
  }

  async logUserLogout(userId) {
    return this._writeLogEntry('USER_LOGOUT', userId, {
      action: 'User logged out',
    });
  }

  async logProfileUpdate(userId, changes) {
    return this._writeLogEntry('PROFILE_UPDATED', userId, {
      action: 'User profile updated',
      changes: Object.keys(changes),
    });
  }

  async logPasswordChange(userId) {
    return this._writeLogEntry('PASSWORD_CHANGED', userId, {
      action: 'Password changed',
    });
  }

  async logEmailVerification(userId) {
    return this._writeLogEntry('EMAIL_VERIFIED', userId, {
      action: 'Email address verified',
    });
  }

  async logAccountDeletion(userId) {
    return this._writeLogEntry('ACCOUNT_DELETED', userId, {
      action: 'User account deleted',
    });
  }

  async logRoleChange(userId, newRole, adminUserId) {
    return this._writeLogEntry('ROLE_CHANGED', userId, {
      action: 'User role changed',
      newRole,
      adminUserId,
    });
  }

  async logUserDeactivation(userId, reason, adminUserId) {
    return this._writeLogEntry('USER_DEACTIVATED', userId, {
      action: 'User account deactivated',
      reason,
      adminUserId,
    });
  }

  async getAuditLogs(criteria = {}) {
    try {
      const content = await this.fs.readFile(this.logFilePath, 'utf8');
      const lines = content.trim().split('\n').filter(line => line.trim());
      
      let logs = lines.map(line => {
        try {
          return JSON.parse(line);
        } catch (error) {
          return null;
        }
      }).filter(log => log !== null);

      // Apply filters
      if (criteria.userId) {
        logs = logs.filter(log => log.userId === criteria.userId);
      }

      if (criteria.eventType) {
        logs = logs.filter(log => log.eventType === criteria.eventType);
      }

      if (criteria.startDate) {
        const startDate = new Date(criteria.startDate);
        logs = logs.filter(log => new Date(log.timestamp) >= startDate);
      }

      if (criteria.endDate) {
        const endDate = new Date(criteria.endDate);
        logs = logs.filter(log => new Date(log.timestamp) <= endDate);
      }

      // Sort by timestamp (newest first)
      logs.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

      // Apply pagination
      const page = criteria.page || 1;
      const limit = criteria.limit || 50;
      const offset = (page - 1) * limit;
      const paginatedLogs = logs.slice(offset, offset + limit);

      return {
        logs: paginatedLogs,
        pagination: {
          page,
          limit,
          total: logs.length,
          pages: Math.ceil(logs.length / limit),
        },
      };
    } catch (error) {
      if (error.code === 'ENOENT') {
        return {
          logs: [],
          pagination: { page: 1, limit: 50, total: 0, pages: 0 },
        };
      }

      this.logger?.error('Error reading audit log file', { error: error.message });
      throw createError.external('AuditLogService', 'Failed to read audit logs', error);
    }
  }

  async _writeLogEntry(eventType, userId, details = {}) {
    try {
      const logEntry = {
        id: this._generateId(),
        eventType,
        userId,
        details,
        timestamp: new Date().toISOString(),
      };

      // Ensure log directory exists
      await this.fs.mkdir(this.path.dirname(this.logFilePath), { recursive: true });

      // Append log entry
      await this.fs.appendFile(
        this.logFilePath, 
        JSON.stringify(logEntry) + '\n'
      );

      this.logger?.info('Audit log entry written', {
        id: logEntry.id,
        eventType,
        userId,
        action: details.action,
      });

      return logEntry;
    } catch (error) {
      this.logger?.error('Error writing audit log entry', {
        eventType,
        userId,
        error: error.message,
      });

      // Don't throw error for audit logging failures
      return null;
    }
  }

  _generateId() {
    return `audit_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

/**
 * Mock Audit Log Service (for testing)
 */
class MockAuditLogService extends IAuditLogService {
  constructor() {
    super();
    this.logs = [];
    this.shouldFail = false;
  }

  async logUserRegistration(userId) {
    return this._mockLog('USER_REGISTERED', userId, { action: 'User account created' });
  }

  async logUserLogin(userId, email) {
    return this._mockLog('USER_LOGIN', userId, { action: 'User logged in', email });
  }

  async logUserLogout(userId) {
    return this._mockLog('USER_LOGOUT', userId, { action: 'User logged out' });
  }

  async logProfileUpdate(userId, changes) {
    return this._mockLog('PROFILE_UPDATED', userId, { 
      action: 'User profile updated', 
      changes: Object.keys(changes) 
    });
  }

  async logPasswordChange(userId) {
    return this._mockLog('PASSWORD_CHANGED', userId, { action: 'Password changed' });
  }

  async logEmailVerification(userId) {
    return this._mockLog('EMAIL_VERIFIED', userId, { action: 'Email address verified' });
  }

  async logAccountDeletion(userId) {
    return this._mockLog('ACCOUNT_DELETED', userId, { action: 'User account deleted' });
  }

  async logRoleChange(userId, newRole, adminUserId) {
    return this._mockLog('ROLE_CHANGED', userId, { 
      action: 'User role changed', 
      newRole, 
      adminUserId 
    });
  }

  async logUserDeactivation(userId, reason, adminUserId) {
    return this._mockLog('USER_DEACTIVATED', userId, { 
      action: 'User account deactivated', 
      reason, 
      adminUserId 
    });
  }

  async getAuditLogs(criteria = {}) {
    let filteredLogs = [...this.logs];

    if (criteria.userId) {
      filteredLogs = filteredLogs.filter(log => log.userId === criteria.userId);
    }

    if (criteria.eventType) {
      filteredLogs = filteredLogs.filter(log => log.eventType === criteria.eventType);
    }

    // Apply pagination
    const page = criteria.page || 1;
    const limit = criteria.limit || 50;
    const offset = (page - 1) * limit;
    const paginatedLogs = filteredLogs.slice(offset, offset + limit);

    return {
      logs: paginatedLogs,
      pagination: {
        page,
        limit,
        total: filteredLogs.length,
        pages: Math.ceil(filteredLogs.length / limit),
      },
    };
  }

  async _mockLog(eventType, userId, details) {
    if (this.shouldFail) {
      throw new Error('Mock audit log service failure');
    }

    const logEntry = {
      id: this._generateId(),
      eventType,
      userId,
      details,
      timestamp: new Date().toISOString(),
    };

    this.logs.push(logEntry);
    return logEntry;
  }

  // Testing utilities
  getLogs() {
    return [...this.logs];
  }

  getLogsByType(eventType) {
    return this.logs.filter(log => log.eventType === eventType);
  }

  getLogsByUser(userId) {
    return this.logs.filter(log => log.userId === userId);
  }

  reset() {
    this.logs = [];
    this.shouldFail = false;
  }

  setShouldFail(shouldFail) {
    this.shouldFail = shouldFail;
  }

  _generateId() {
    return `audit_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

/**
 * Factory function to create audit log service instances
 */
function createAuditLogService(config, database = null, logger = null) {
  if (config.mock || process.env.NODE_ENV === 'test') {
    return new MockAuditLogService();
  }

  switch (config.type) {
    case 'database':
      if (!database) {
        throw createError.config('Database instance required for database audit log service');
      }
      return new DatabaseAuditLogService(database, logger);
    
    case 'file':
      return new FileAuditLogService(config.logFilePath || './audit.log', logger);
    
    default:
      throw createError.config(`Unsupported audit log service type: ${config.type}`, 'AUDIT_LOG_TYPE');
  }
}

module.exports = {
  IAuditLogService,
  DatabaseAuditLogService,
  FileAuditLogService,
  MockAuditLogService,
  createAuditLogService,
};