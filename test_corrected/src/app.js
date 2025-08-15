/**
 * Main Application Entry Point
 * Initializes Express server with all middleware, routes, and services
 * Implements hexagonal architecture with dependency injection
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const cookieParser = require('cookie-parser');
const compression = require('compression');
const rateLimit = require('express-rate-limit');

// Application imports
const { config } = require('./shared/config');
const { createLogger, requestLogger, errorLogger } = require('./shared/logger');
const { errorHandler, asyncHandler } = require('./shared/errors');
const { createHashingService } = require('./shared/utils/hashingService');

// Infrastructure imports
const { PostgreSQLUserRepository, InMemoryUserRepository } = require('./infrastructure/repositories/UserRepository');
const { createEmailService } = require('./infrastructure/external/EmailService');
const { createAuditLogService } = require('./infrastructure/external/AuditLogService');

// Application services
const { UserService } = require('./application/services/UserService');

// Presentation layer
const { createUserRoutes } = require('./presentation/routes/userRoutes');

/**
 * Application Factory Class
 * Creates and configures the Express application with all dependencies
 */
class ApplicationFactory {
  constructor() {
    this.app = null;
    this.dependencies = {};
    this.isInitialized = false;
  }

  /**
   * Create and configure the Express application
   * @param {Object} options - Configuration options
   * @returns {express.Application} Configured Express app
   */
  async create(options = {}) {
    if (this.isInitialized) {
      return this.app;
    }

    try {
      // Load configuration
      const appConfig = config.load();
      
      // Initialize core dependencies
      await this._initializeDependencies(appConfig, options);
      
      // Create Express application
      this.app = express();
      
      // Configure middleware
      this._configureMiddleware(appConfig);
      
      // Configure routes
      this._configureRoutes();
      
      // Configure error handling
      this._configureErrorHandling();
      
      this.isInitialized = true;
      
      this.dependencies.logger.info('Application initialized successfully', {
        environment: appConfig.server.env,
        port: appConfig.server.port,
      });
      
      return this.app;
    } catch (error) {
      console.error('Failed to create application:', error);
      throw error;
    }
  }

  /**
   * Get application dependencies (for testing)
   * @returns {Object} Application dependencies
   */
  getDependencies() {
    return this.dependencies;
  }

  /**
   * Close application and cleanup resources
   */
  async close() {
    if (this.dependencies.database) {
      await this.dependencies.database.close();
    }
    
    if (this.dependencies.logger) {
      await this.dependencies.logger.shutdown?.();
    }
    
    this.isInitialized = false;
  }

  /**
   * Initialize all application dependencies
   * @private
   * @param {Object} appConfig - Application configuration
   * @param {Object} options - Override options
   */
  async _initializeDependencies(appConfig, options = {}) {
    // Logger
    this.dependencies.logger = options.logger || createLogger('app', {
      level: appConfig.logging.level,
      format: appConfig.logging.format,
      silent: options.silent || false,
    });

    // Database (simplified for this implementation)
    if (appConfig.server.env === 'test' || options.useInMemoryDb) {
      this.dependencies.database = null; // In-memory doesn't need connection
      this.dependencies.userRepository = new InMemoryUserRepository(this.dependencies.logger);
    } else {
      // In a real implementation, you would initialize database connection here
      this.dependencies.database = options.database || null;
      this.dependencies.userRepository = new PostgreSQLUserRepository(
        this.dependencies.database, 
        this.dependencies.logger
      );
    }

    // External services
    this.dependencies.emailService = options.emailService || createEmailService(
      { ...appConfig.email, mock: options.mockServices || appConfig.server.env === 'test' },
      this.dependencies.logger
    );

    this.dependencies.auditLogService = options.auditLogService || createAuditLogService(
      { 
        type: options.auditLogType || 'file',
        logFilePath: options.auditLogPath || './logs/audit.log',
        mock: options.mockServices || appConfig.server.env === 'test',
      },
      this.dependencies.database,
      this.dependencies.logger
    );

    this.dependencies.hashingService = options.hashingService || createHashingService(
      { 
        saltRounds: appConfig.auth.bcrypt.saltRounds,
        mock: options.mockServices || appConfig.server.env === 'test',
      },
      this.dependencies.logger
    );

    // Application services
    this.dependencies.userService = options.userService || new UserService(
      this.dependencies.userRepository,
      this.dependencies.emailService,
      this.dependencies.hashingService,
      this.dependencies.auditLogService
    );

    // Rate limiter (optional)
    this.dependencies.rateLimiter = options.rateLimiter || null;
  }

  /**
   * Configure Express middleware
   * @private
   * @param {Object} appConfig - Application configuration
   */
  _configureMiddleware(appConfig) {
    // Security middleware
    if (appConfig.security.helmet.enabled) {
      this.app.use(helmet({
        contentSecurityPolicy: appConfig.security.helmet.contentSecurityPolicy,
        hsts: appConfig.security.helmet.hsts,
      }));
    }

    // CORS middleware
    this.app.use(cors({
      origin: appConfig.server.cors.origin,
      credentials: appConfig.server.cors.credentials,
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Correlation-ID'],
    }));

    // Request parsing middleware
    this.app.use(express.json({ limit: '10mb' }));
    this.app.use(express.urlencoded({ extended: true, limit: '10mb' }));
    this.app.use(cookieParser());

    // Compression middleware
    this.app.use(compression());

    // Request logging middleware
    this.app.use(requestLogger(this.dependencies.logger));

    // Global rate limiting
    if (appConfig.security.rateLimit.max > 0) {
      const limiter = rateLimit({
        windowMs: appConfig.security.rateLimit.windowMs,
        max: appConfig.security.rateLimit.max,
        skipSuccessfulRequests: appConfig.security.rateLimit.skipSuccessfulRequests,
        message: {
          error: {
            code: 'RATE_LIMIT_EXCEEDED',
            message: 'Too many requests from this IP, please try again later',
          },
        },
        standardHeaders: true,
        legacyHeaders: false,
      });
      
      this.app.use(limiter);
    }

    // Health check endpoint (before other routes)
    this.app.get('/health', (req, res) => {
      res.json({
        success: true,
        message: 'Service is healthy',
        timestamp: new Date().toISOString(),
        environment: appConfig.server.env,
        uptime: process.uptime(),
      });
    });

    // API versioning
    this.app.use('/api/v1', express.Router());
  }

  /**
   * Configure application routes
   * @private
   */
  _configureRoutes() {
    // Mount user routes
    const userRoutes = createUserRoutes({
      userService: this.dependencies.userService,
      userRepository: this.dependencies.userRepository,
      logger: this.dependencies.logger,
      rateLimiter: this.dependencies.rateLimiter,
    });
    
    this.app.use('/api/v1/users', userRoutes);

    // Root endpoint
    this.app.get('/', (req, res) => {
      res.json({
        name: 'SPARC Application API',
        version: '1.0.0',
        description: 'TDD-driven REST API following hexagonal architecture',
        documentation: '/api/v1/users/docs',
        health: '/health',
        timestamp: new Date().toISOString(),
      });
    });

    // 404 handler for undefined routes
    this.app.use('*', (req, res, next) => {
      const error = new Error(`Route ${req.method} ${req.originalUrl} not found`);
      error.statusCode = 404;
      error.code = 'ROUTE_NOT_FOUND';
      next(error);
    });
  }

  /**
   * Configure error handling middleware
   * @private
   */
  _configureErrorHandling() {
    // Error logging middleware
    this.app.use(errorLogger(this.dependencies.logger));
    
    // Global error handler
    this.app.use(errorHandler);
  }
}

/**
 * Create application instance
 * @param {Object} options - Configuration options
 * @returns {Promise<express.Application>} Configured Express app
 */
async function createApplication(options = {}) {
  const factory = new ApplicationFactory();
  return factory.create(options);
}

/**
 * Start the server
 * @param {Object} options - Server options
 * @returns {Promise<Object>} Server instance and configuration
 */
async function startServer(options = {}) {
  try {
    const app = await createApplication(options);
    const appConfig = config.load();
    
    const port = options.port || appConfig.server.port;
    const host = options.host || appConfig.server.host;
    
    return new Promise((resolve, reject) => {
      const server = app.listen(port, host, (error) => {
        if (error) {
          reject(error);
          return;
        }
        
        const logger = options.logger || createLogger('server');
        logger.info('Server started successfully', {
          port,
          host,
          environment: appConfig.server.env,
          pid: process.pid,
        });
        
        resolve({
          server,
          app,
          config: appConfig,
          port,
          host,
        });
      });

      // Graceful shutdown handlers
      const shutdown = async (signal) => {
        logger?.info(`Received ${signal}, starting graceful shutdown`);
        
        server.close(async () => {
          logger?.info('HTTP server closed');
          
          // Cleanup application resources
          if (app.factory) {
            await app.factory.close();
          }
          
          logger?.info('Graceful shutdown completed');
          process.exit(0);
        });
        
        // Force shutdown after timeout
        setTimeout(() => {
          logger?.error('Forced shutdown due to timeout');
          process.exit(1);
        }, 10000);
      };

      process.on('SIGTERM', () => shutdown('SIGTERM'));
      process.on('SIGINT', () => shutdown('SIGINT'));
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    throw error;
  }
}

module.exports = {
  ApplicationFactory,
  createApplication,
  startServer,
};