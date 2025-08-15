/**
 * Configuration Management System
 * Environment-safe configuration with validation and defaults
 */

const path = require('path');
const { z } = require('zod');

// Configuration Schema Definition
const ConfigSchema = z.object({
  // Server Configuration
  server: z.object({
    port: z.number().min(1000).max(65535).default(3000),
    host: z.string().default('localhost'),
    env: z.enum(['development', 'test', 'staging', 'production']).default('development'),
    cors: z.object({
      origin: z.array(z.string()).default(['http://localhost:3000']),
      credentials: z.boolean().default(true),
    }),
  }),

  // Database Configuration
  database: z.object({
    type: z.enum(['postgres', 'sqlite', 'mysql']).default('postgres'),
    host: z.string().default('localhost'),
    port: z.number().default(5432),
    name: z.string().min(1),
    username: z.string().min(1),
    password: z.string().min(1),
    ssl: z.boolean().default(false),
    pool: z.object({
      min: z.number().default(2),
      max: z.number().default(10),
      acquireTimeoutMillis: z.number().default(30000),
      idleTimeoutMillis: z.number().default(30000),
    }),
  }),

  // Authentication Configuration
  auth: z.object({
    jwt: z.object({
      secret: z.string().min(32),
      expiresIn: z.string().default('24h'),
      refreshExpiresIn: z.string().default('7d'),
      issuer: z.string().default('sparc-app'),
      audience: z.string().default('sparc-users'),
    }),
    bcrypt: z.object({
      saltRounds: z.number().min(10).max(15).default(12),
    }),
    rateLimiting: z.object({
      windowMs: z.number().default(15 * 60 * 1000), // 15 minutes
      maxAttempts: z.number().default(5),
      skipSuccessfulRequests: z.boolean().default(true),
    }),
  }),

  // Redis Configuration (Caching/Sessions)
  redis: z.object({
    host: z.string().default('localhost'),
    port: z.number().default(6379),
    password: z.string().optional(),
    db: z.number().default(0),
    keyPrefix: z.string().default('sparc:'),
    ttl: z.number().default(3600), // 1 hour
  }),

  // Email Configuration
  email: z.object({
    provider: z.enum(['smtp', 'sendgrid', 'ses']).default('smtp'),
    from: z.string().email(),
    smtp: z.object({
      host: z.string().default('localhost'),
      port: z.number().default(587),
      secure: z.boolean().default(false),
      auth: z.object({
        user: z.string(),
        pass: z.string(),
      }),
    }).optional(),
    sendgrid: z.object({
      apiKey: z.string(),
    }).optional(),
    ses: z.object({
      region: z.string().default('us-east-1'),
      accessKeyId: z.string(),
      secretAccessKey: z.string(),
    }).optional(),
  }),

  // Logging Configuration
  logging: z.object({
    level: z.enum(['error', 'warn', 'info', 'debug']).default('info'),
    format: z.enum(['json', 'simple']).default('json'),
    file: z.object({
      enabled: z.boolean().default(true),
      filename: z.string().default('app.log'),
      maxsize: z.number().default(5242880), // 5MB
      maxFiles: z.number().default(5),
    }),
    console: z.object({
      enabled: z.boolean().default(true),
      colorize: z.boolean().default(true),
    }),
  }),

  // Security Configuration
  security: z.object({
    helmet: z.object({
      enabled: z.boolean().default(true),
      contentSecurityPolicy: z.boolean().default(true),
      hsts: z.boolean().default(true),
    }),
    rateLimit: z.object({
      windowMs: z.number().default(15 * 60 * 1000),
      max: z.number().default(100),
      skipSuccessfulRequests: z.boolean().default(false),
    }),
    session: z.object({
      secret: z.string().min(32),
      secure: z.boolean().default(false),
      httpOnly: z.boolean().default(true),
      maxAge: z.number().default(24 * 60 * 60 * 1000), // 24 hours
    }),
  }),

  // Feature Flags
  features: z.object({
    userRegistration: z.boolean().default(true),
    emailVerification: z.boolean().default(true),
    passwordReset: z.boolean().default(true),
    socialLogin: z.boolean().default(false),
    twoFactorAuth: z.boolean().default(false),
    auditLogging: z.boolean().default(true),
    performanceMonitoring: z.boolean().default(false),
  }),
});

/**
 * Configuration Manager Class
 */
class ConfigManager {
  constructor() {
    this.config = null;
    this.isLoaded = false;
  }

  /**
   * Load and validate configuration from environment
   * @returns {Object} Validated configuration
   */
  load() {
    if (this.isLoaded && this.config) {
      return this.config;
    }

    try {
      const rawConfig = this._loadFromEnvironment();
      this.config = ConfigSchema.parse(rawConfig);
      this.isLoaded = true;
      
      // Validate environment-specific requirements
      this._validateEnvironmentRequirements();
      
      return this.config;
    } catch (error) {
      throw new Error(`Configuration validation failed: ${error.message}`);
    }
  }

  /**
   * Get configuration value by path
   * @param {string} path - Dot-separated path to config value
   * @param {*} defaultValue - Default value if path not found
   * @returns {*} Configuration value
   */
  get(path, defaultValue = undefined) {
    if (!this.isLoaded) {
      this.load();
    }

    const keys = path.split('.');
    let value = this.config;

    for (const key of keys) {
      if (value && typeof value === 'object' && key in value) {
        value = value[key];
      } else {
        return defaultValue;
      }
    }

    return value;
  }

  /**
   * Check if configuration is loaded
   * @returns {boolean}
   */
  isConfigLoaded() {
    return this.isLoaded && this.config !== null;
  }

  /**
   * Get current environment
   * @returns {string}
   */
  getEnvironment() {
    return this.get('server.env', 'development');
  }

  /**
   * Check if running in production
   * @returns {boolean}
   */
  isProduction() {
    return this.getEnvironment() === 'production';
  }

  /**
   * Check if running in development
   * @returns {boolean}
   */
  isDevelopment() {
    return this.getEnvironment() === 'development';
  }

  /**
   * Check if running in test environment
   * @returns {boolean}
   */
  isTest() {
    return this.getEnvironment() === 'test';
  }

  /**
   * Load configuration from environment variables
   * @private
   * @returns {Object} Raw configuration object
   */
  _loadFromEnvironment() {
    const env = process.env;

    return {
      server: {
        port: parseInt(env.PORT) || 3000,
        host: env.HOST || 'localhost',
        env: env.NODE_ENV || 'development',
        cors: {
          origin: env.CORS_ORIGIN ? env.CORS_ORIGIN.split(',') : ['http://localhost:3000'],
          credentials: env.CORS_CREDENTIALS === 'true',
        },
      },

      database: {
        type: env.DB_TYPE || 'postgres',
        host: env.DB_HOST || 'localhost',
        port: parseInt(env.DB_PORT) || 5432,
        name: env.DB_NAME || 'sparc_app',
        username: env.DB_USERNAME || 'postgres',
        password: env.DB_PASSWORD || 'password',
        ssl: env.DB_SSL === 'true',
        pool: {
          min: parseInt(env.DB_POOL_MIN) || 2,
          max: parseInt(env.DB_POOL_MAX) || 10,
          acquireTimeoutMillis: parseInt(env.DB_POOL_ACQUIRE_TIMEOUT) || 30000,
          idleTimeoutMillis: parseInt(env.DB_POOL_IDLE_TIMEOUT) || 30000,
        },
      },

      auth: {
        jwt: {
          secret: env.JWT_SECRET || this._generateSecret(),
          expiresIn: env.JWT_EXPIRES_IN || '24h',
          refreshExpiresIn: env.JWT_REFRESH_EXPIRES_IN || '7d',
          issuer: env.JWT_ISSUER || 'sparc-app',
          audience: env.JWT_AUDIENCE || 'sparc-users',
        },
        bcrypt: {
          saltRounds: parseInt(env.BCRYPT_SALT_ROUNDS) || 12,
        },
        rateLimiting: {
          windowMs: parseInt(env.AUTH_RATE_LIMIT_WINDOW) || (15 * 60 * 1000),
          maxAttempts: parseInt(env.AUTH_RATE_LIMIT_MAX) || 5,
          skipSuccessfulRequests: env.AUTH_RATE_LIMIT_SKIP_SUCCESS === 'true',
        },
      },

      redis: {
        host: env.REDIS_HOST || 'localhost',
        port: parseInt(env.REDIS_PORT) || 6379,
        password: env.REDIS_PASSWORD,
        db: parseInt(env.REDIS_DB) || 0,
        keyPrefix: env.REDIS_KEY_PREFIX || 'sparc:',
        ttl: parseInt(env.REDIS_TTL) || 3600,
      },

      email: {
        provider: env.EMAIL_PROVIDER || 'smtp',
        from: env.EMAIL_FROM || 'noreply@example.com',
        smtp: env.EMAIL_PROVIDER === 'smtp' ? {
          host: env.SMTP_HOST || 'localhost',
          port: parseInt(env.SMTP_PORT) || 587,
          secure: env.SMTP_SECURE === 'true',
          auth: {
            user: env.SMTP_USER || '',
            pass: env.SMTP_PASS || '',
          },
        } : undefined,
        sendgrid: env.EMAIL_PROVIDER === 'sendgrid' ? {
          apiKey: env.SENDGRID_API_KEY || '',
        } : undefined,
        ses: env.EMAIL_PROVIDER === 'ses' ? {
          region: env.AWS_REGION || 'us-east-1',
          accessKeyId: env.AWS_ACCESS_KEY_ID || '',
          secretAccessKey: env.AWS_SECRET_ACCESS_KEY || '',
        } : undefined,
      },

      logging: {
        level: env.LOG_LEVEL || 'info',
        format: env.LOG_FORMAT || 'json',
        file: {
          enabled: env.LOG_FILE_ENABLED !== 'false',
          filename: env.LOG_FILE_NAME || 'app.log',
          maxsize: parseInt(env.LOG_FILE_MAX_SIZE) || 5242880,
          maxFiles: parseInt(env.LOG_FILE_MAX_FILES) || 5,
        },
        console: {
          enabled: env.LOG_CONSOLE_ENABLED !== 'false',
          colorize: env.LOG_CONSOLE_COLORIZE !== 'false',
        },
      },

      security: {
        helmet: {
          enabled: env.SECURITY_HELMET_ENABLED !== 'false',
          contentSecurityPolicy: env.SECURITY_CSP_ENABLED !== 'false',
          hsts: env.SECURITY_HSTS_ENABLED !== 'false',
        },
        rateLimit: {
          windowMs: parseInt(env.RATE_LIMIT_WINDOW) || (15 * 60 * 1000),
          max: parseInt(env.RATE_LIMIT_MAX) || 100,
          skipSuccessfulRequests: env.RATE_LIMIT_SKIP_SUCCESS === 'true',
        },
        session: {
          secret: env.SESSION_SECRET || this._generateSecret(),
          secure: env.SESSION_SECURE === 'true',
          httpOnly: env.SESSION_HTTP_ONLY !== 'false',
          maxAge: parseInt(env.SESSION_MAX_AGE) || (24 * 60 * 60 * 1000),
        },
      },

      features: {
        userRegistration: env.FEATURE_USER_REGISTRATION !== 'false',
        emailVerification: env.FEATURE_EMAIL_VERIFICATION !== 'false',
        passwordReset: env.FEATURE_PASSWORD_RESET !== 'false',
        socialLogin: env.FEATURE_SOCIAL_LOGIN === 'true',
        twoFactorAuth: env.FEATURE_2FA === 'true',
        auditLogging: env.FEATURE_AUDIT_LOGGING !== 'false',
        performanceMonitoring: env.FEATURE_PERF_MONITORING === 'true',
      },
    };
  }

  /**
   * Validate environment-specific requirements
   * @private
   */
  _validateEnvironmentRequirements() {
    const env = this.getEnvironment();

    if (env === 'production') {
      // Production-specific validations
      if (this.get('auth.jwt.secret').length < 32) {
        throw new Error('JWT secret must be at least 32 characters in production');
      }

      if (this.get('security.session.secret').length < 32) {
        throw new Error('Session secret must be at least 32 characters in production');
      }

      if (!this.get('security.session.secure')) {
        console.warn('WARNING: Session security disabled in production');
      }

      if (!this.get('database.ssl')) {
        console.warn('WARNING: Database SSL disabled in production');
      }
    }

    // Feature-specific validations
    if (this.get('features.emailVerification') && !this.get('email.from')) {
      throw new Error('Email configuration required when email verification is enabled');
    }
  }

  /**
   * Generate a secure random secret
   * @private
   * @returns {string}
   */
  _generateSecret() {
    return require('crypto').randomBytes(32).toString('hex');
  }
}

// Create singleton instance
const configManager = new ConfigManager();

// Export both the manager and a convenience function
module.exports = {
  ConfigManager,
  config: configManager,
  
  // Convenience functions
  load: () => configManager.load(),
  get: (path, defaultValue) => configManager.get(path, defaultValue),
  isProduction: () => configManager.isProduction(),
  isDevelopment: () => configManager.isDevelopment(),
  isTest: () => configManager.isTest(),
  getEnvironment: () => configManager.getEnvironment(),
};