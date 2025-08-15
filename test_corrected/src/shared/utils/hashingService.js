/**
 * Hashing Service
 * Secure password hashing using bcrypt with configurable salt rounds
 */

const bcrypt = require('bcrypt');
const { createError } = require('../errors');

/**
 * Hashing Service Interface
 */
class IHashingService {
  async hash(plainText) {
    throw new Error('Method not implemented');
  }

  async verify(plainText, hashedText) {
    throw new Error('Method not implemented');
  }

  async compare(plainText, hashedText) {
    throw new Error('Method not implemented');
  }
}

/**
 * Bcrypt Hashing Service Implementation
 */
class BcryptHashingService extends IHashingService {
  constructor(saltRounds = 12, logger = null) {
    super();
    this.saltRounds = saltRounds;
    this.logger = logger;
    
    // Validate salt rounds
    if (saltRounds < 10 || saltRounds > 15) {
      throw createError.config('Salt rounds must be between 10 and 15', 'BCRYPT_SALT_ROUNDS');
    }
  }

  /**
   * Hash a plain text string
   * @param {string} plainText - Plain text to hash
   * @returns {Promise<string>} Hashed string
   */
  async hash(plainText) {
    try {
      if (!plainText) {
        throw createError.validation('Plain text is required for hashing');
      }

      if (typeof plainText !== 'string') {
        throw createError.validation('Plain text must be a string');
      }

      const startTime = Date.now();
      const hashedText = await bcrypt.hash(plainText, this.saltRounds);
      const duration = Date.now() - startTime;

      if (this.logger) {
        this.logger.debug('Text hashed successfully', {
          saltRounds: this.saltRounds,
          duration,
        });
      }

      return hashedText;
    } catch (error) {
      if (error.name && error.name.includes('Error')) {
        throw error; // Re-throw custom errors
      }

      if (this.logger) {
        this.logger.error('Hashing failed', { error: error.message });
      }

      throw createError.external('HashingService', 'Failed to hash text', error);
    }
  }

  /**
   * Verify a plain text against a hash
   * @param {string} plainText - Plain text to verify
   * @param {string} hashedText - Hashed text to verify against
   * @returns {Promise<boolean>} Verification result
   */
  async verify(plainText, hashedText) {
    try {
      if (!plainText || !hashedText) {
        return false;
      }

      if (typeof plainText !== 'string' || typeof hashedText !== 'string') {
        return false;
      }

      const startTime = Date.now();
      const isValid = await bcrypt.compare(plainText, hashedText);
      const duration = Date.now() - startTime;

      if (this.logger) {
        this.logger.debug('Text verification completed', {
          isValid,
          duration,
        });
      }

      return isValid;
    } catch (error) {
      if (this.logger) {
        this.logger.error('Verification failed', { error: error.message });
      }

      // Return false instead of throwing on verification errors
      // This prevents information disclosure attacks
      return false;
    }
  }

  /**
   * Alias for verify method (for backward compatibility)
   * @param {string} plainText - Plain text to compare
   * @param {string} hashedText - Hashed text to compare against
   * @returns {Promise<boolean>} Comparison result
   */
  async compare(plainText, hashedText) {
    return this.verify(plainText, hashedText);
  }

  /**
   * Get current configuration
   * @returns {Object} Configuration details
   */
  getConfig() {
    return {
      saltRounds: this.saltRounds,
      algorithm: 'bcrypt',
    };
  }

  /**
   * Estimate hashing time for current configuration
   * @returns {Promise<number>} Estimated time in milliseconds
   */
  async estimateHashingTime() {
    const testString = 'test_password_for_benchmarking';
    const startTime = Date.now();
    await this.hash(testString);
    return Date.now() - startTime;
  }

  /**
   * Check if a hash was created with the current salt rounds
   * @param {string} hashedText - Hash to analyze
   * @returns {boolean} Whether hash matches current configuration
   */
  isHashUpToDate(hashedText) {
    try {
      if (!hashedText || typeof hashedText !== 'string') {
        return false;
      }

      // Extract salt rounds from bcrypt hash
      const match = hashedText.match(/^\$2[aby]?\$(\d+)\$/);
      if (!match) {
        return false;
      }

      const hashSaltRounds = parseInt(match[1]);
      return hashSaltRounds === this.saltRounds;
    } catch (error) {
      return false;
    }
  }

  /**
   * Rehash if necessary (upgrade security)
   * @param {string} plainText - Plain text password
   * @param {string} currentHash - Current hash
   * @returns {Promise<string|null>} New hash if rehashing was needed, null otherwise
   */
  async rehashIfNeeded(plainText, currentHash) {
    try {
      // First verify the password is correct
      const isValid = await this.verify(plainText, currentHash);
      if (!isValid) {
        throw createError.auth('Invalid password for rehashing');
      }

      // Check if rehashing is needed
      if (this.isHashUpToDate(currentHash)) {
        return null; // No rehashing needed
      }

      // Rehash with current configuration
      const newHash = await this.hash(plainText);

      if (this.logger) {
        this.logger.info('Password rehashed due to configuration change');
      }

      return newHash;
    } catch (error) {
      if (error.name && error.name.includes('Error')) {
        throw error; // Re-throw custom errors
      }

      throw createError.external('HashingService', 'Failed to rehash password', error);
    }
  }
}

/**
 * Mock Hashing Service (for testing)
 * WARNING: NOT FOR PRODUCTION USE
 */
class MockHashingService extends IHashingService {
  constructor(shouldFail = false) {
    super();
    this.shouldFail = shouldFail;
    this.hashCalls = [];
    this.verifyCalls = [];
  }

  async hash(plainText) {
    this.hashCalls.push({ plainText, timestamp: new Date() });

    if (this.shouldFail) {
      throw new Error('Mock hashing service failure');
    }

    // Simple mock hash (NOT SECURE)
    return `mock_hashed_${plainText}`;
  }

  async verify(plainText, hashedText) {
    this.verifyCalls.push({ plainText, hashedText, timestamp: new Date() });

    if (this.shouldFail) {
      throw new Error('Mock verification service failure');
    }

    // Simple mock verification
    return hashedText === `mock_hashed_${plainText}`;
  }

  async compare(plainText, hashedText) {
    return this.verify(plainText, hashedText);
  }

  // Testing utilities
  getCallHistory() {
    return {
      hashCalls: [...this.hashCalls],
      verifyCalls: [...this.verifyCalls],
    };
  }

  reset() {
    this.hashCalls = [];
    this.verifyCalls = [];
  }

  setShouldFail(shouldFail) {
    this.shouldFail = shouldFail;
  }
}

/**
 * Factory function to create hashing service instances
 * @param {Object} config - Configuration object
 * @param {Object} logger - Logger instance
 * @returns {IHashingService} Hashing service instance
 */
function createHashingService(config = {}, logger = null) {
  const {
    type = 'bcrypt',
    saltRounds = 12,
    mock = false,
  } = config;

  if (mock || process.env.NODE_ENV === 'test') {
    return new MockHashingService();
  }

  if (type === 'bcrypt') {
    return new BcryptHashingService(saltRounds, logger);
  }

  throw createError.config(`Unsupported hashing service type: ${type}`, 'HASHING_SERVICE_TYPE');
}

module.exports = {
  IHashingService,
  BcryptHashingService,
  MockHashingService,
  createHashingService,
};