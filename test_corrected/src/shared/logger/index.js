/**
 * Logging Service
 * Structured logging with Winston, supporting multiple transports and formats
 */

const winston = require('winston');
const path = require('path');
const { config } = require('../config');

/**
 * Custom log levels and colors
 */
const logLevels = {
  error: 0,
  warn: 1,
  info: 2,
  http: 3,
  debug: 4,
};

const logColors = {
  error: 'red',
  warn: 'yellow',
  info: 'green',
  http: 'magenta',
  debug: 'cyan',
};

winston.addColors(logColors);

/**
 * Log Format Configurations
 */
const createLogFormat = (colorize = false) => {
  const formats = [
    winston.format.timestamp({
      format: 'YYYY-MM-DD HH:mm:ss',
    }),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.json(),
  ];

  if (colorize) {
    formats.push(winston.format.colorize({ all: true }));
  }

  // Custom format for structured logging
  formats.push(
    winston.format.printf(({ timestamp, level, message, ...meta }) => {
      let logString = `${timestamp} [${level}]: ${message}`;
      
      // Add metadata if present
      if (Object.keys(meta).length > 0) {
        logString += ` ${JSON.stringify(meta, null, 2)}`;
      }
      
      return logString;
    })
  );

  return winston.format.combine(...formats);
};

/**
 * Logger Factory
 */
class LoggerFactory {
  constructor() {
    this.loggers = new Map();
    this.defaultConfig = this._getDefaultConfig();
  }

  /**
   * Create or get logger instance
   * @param {string} name - Logger name
   * @param {Object} options - Logger options
   * @returns {winston.Logger} Logger instance
   */
  create(name = 'default', options = {}) {
    if (this.loggers.has(name)) {
      return this.loggers.get(name);
    }

    const loggerConfig = {
      ...this.defaultConfig,
      ...options,
    };

    const logger = winston.createLogger({
      level: loggerConfig.level,
      levels: logLevels,
      transports: this._createTransports(loggerConfig),
      exitOnError: false,
      silent: loggerConfig.silent,
    });

    // Add custom methods
    this._addCustomMethods(logger, name);

    this.loggers.set(name, logger);
    return logger;
  }

  /**
   * Get existing logger
   * @param {string} name - Logger name
   * @returns {winston.Logger} Logger instance
   */
  get(name = 'default') {
    return this.loggers.get(name) || this.create(name);
  }

  /**
   * Create child logger with additional context
   * @param {string} parentName - Parent logger name
   * @param {Object} context - Additional context
   * @returns {winston.Logger} Child logger
   */
  child(parentName = 'default', context = {}) {
    const parent = this.get(parentName);
    const childName = `${parentName}:${Date.now()}`;
    
    const child = parent.child(context);
    this.loggers.set(childName, child);
    
    return child;
  }

  /**
   * Get default configuration
   * @private
   * @returns {Object} Default config
   */
  _getDefaultConfig() {
    try {
      return {
        level: config.get('logging.level', 'info'),
        format: config.get('logging.format', 'json'),
        silent: config.isTest(),
        file: {
          enabled: config.get('logging.file.enabled', true),
          filename: config.get('logging.file.filename', 'app.log'),
          maxsize: config.get('logging.file.maxsize', 5242880),
          maxFiles: config.get('logging.file.maxFiles', 5),
        },
        console: {
          enabled: config.get('logging.console.enabled', true),
          colorize: config.get('logging.console.colorize', true),
        },
      };
    } catch (error) {
      // Fallback config if config system fails
      return {
        level: 'info',
        format: 'json',
        silent: process.env.NODE_ENV === 'test',
        file: {
          enabled: true,
          filename: 'app.log',
          maxsize: 5242880,
          maxFiles: 5,
        },
        console: {
          enabled: true,
          colorize: true,
        },
      };
    }
  }

  /**
   * Create winston transports
   * @private
   * @param {Object} config - Logger configuration
   * @returns {Array} Winston transports
   */
  _createTransports(config) {
    const transports = [];

    // Console transport
    if (config.console.enabled && !config.silent) {
      transports.push(
        new winston.transports.Console({
          level: config.level,
          format: createLogFormat(config.console.colorize),
          handleExceptions: true,
          handleRejections: true,
        })
      );
    }

    // File transport
    if (config.file.enabled && !config.silent) {
      transports.push(
        new winston.transports.File({
          level: config.level,
          filename: path.resolve(process.cwd(), 'logs', config.file.filename),
          format: createLogFormat(false),
          maxsize: config.file.maxsize,
          maxFiles: config.file.maxFiles,
          handleExceptions: true,
          handleRejections: true,
        })
      );

      // Separate error log file
      transports.push(
        new winston.transports.File({
          level: 'error',
          filename: path.resolve(process.cwd(), 'logs', 'error.log'),
          format: createLogFormat(false),
          maxsize: config.file.maxsize,
          maxFiles: config.file.maxFiles,
          handleExceptions: true,
          handleRejections: true,
        })
      );
    }

    return transports;
  }

  /**
   * Add custom methods to logger
   * @private
   * @param {winston.Logger} logger - Logger instance
   * @param {string} name - Logger name
   */
  _addCustomMethods(logger, name) {
    // Add HTTP request logging method
    logger.http = (message, meta = {}) => {
      logger.log('http', message, { service: name, ...meta });
    };

    // Add structured logging methods
    logger.security = (message, meta = {}) => {
      logger.warn(message, { type: 'security', service: name, ...meta });
    };

    logger.audit = (message, meta = {}) => {
      logger.info(message, { type: 'audit', service: name, ...meta });
    };

    logger.performance = (message, meta = {}) => {
      logger.info(message, { type: 'performance', service: name, ...meta });
    };

    // Add request correlation method
    logger.withCorrelation = (correlationId) => {
      return logger.child({ correlationId });
    };

    // Add timing utilities
    logger.time = (label) => {
      const start = Date.now();
      return {
        end: (message = `Timer ${label} completed`, meta = {}) => {
          const duration = Date.now() - start;
          logger.info(message, { 
            type: 'timing',
            label,
            duration,
            service: name,
            ...meta,
          });
          return duration;
        },
      };
    };

    // Add context-aware logging
    logger.withContext = (context) => {
      return logger.child({ context });
    };

    // Add business event logging
    logger.event = (eventName, data = {}) => {
      logger.info(`Event: ${eventName}`, {
        type: 'business_event',
        event: eventName,
        data,
        service: name,
      });
    };
  }

  /**
   * Close all loggers
   */
  async shutdown() {
    const promises = Array.from(this.loggers.values()).map(logger => {
      return new Promise((resolve) => {
        logger.end(() => resolve());
      });
    });

    await Promise.all(promises);
    this.loggers.clear();
  }
}

// Create singleton instance
const loggerFactory = new LoggerFactory();

/**
 * Express.js request logger middleware
 */
const requestLogger = (logger) => {
  return (req, res, next) => {
    const startTime = Date.now();
    const correlationId = req.headers['x-correlation-id'] || 
                         `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

    // Add correlation ID to request
    req.correlationId = correlationId;
    res.setHeader('X-Correlation-ID', correlationId);

    // Create request-specific logger
    req.logger = logger.withCorrelation(correlationId);

    // Log request start
    req.logger.http('Request started', {
      method: req.method,
      url: req.url,
      ip: req.ip,
      userAgent: req.get('User-Agent'),
    });

    // Log response when finished
    res.on('finish', () => {
      const duration = Date.now() - startTime;
      const logLevel = res.statusCode >= 400 ? 'warn' : 'http';
      
      req.logger[logLevel]('Request completed', {
        method: req.method,
        url: req.url,
        statusCode: res.statusCode,
        duration,
        contentLength: res.get('Content-Length'),
      });
    });

    next();
  };
};

/**
 * Error logger middleware
 */
const errorLogger = (logger) => {
  return (error, req, res, next) => {
    const requestLogger = req.logger || logger;
    
    requestLogger.error('Request error occurred', {
      error: {
        name: error.name,
        message: error.message,
        stack: error.stack,
        code: error.code,
        statusCode: error.statusCode,
      },
      request: {
        method: req.method,
        url: req.url,
        headers: req.headers,
        body: req.body,
        params: req.params,
        query: req.query,
      },
    });

    next(error);
  };
};

/**
 * Mock logger for testing
 */
const createMockLogger = () => {
  const calls = {
    error: [],
    warn: [],
    info: [],
    http: [],
    debug: [],
    security: [],
    audit: [],
    performance: [],
  };

  const mockLogger = {};
  
  Object.keys(calls).forEach(level => {
    mockLogger[level] = (message, meta = {}) => {
      calls[level].push({ message, meta, timestamp: new Date() });
    };
  });

  // Add utility methods
  mockLogger.time = (label) => ({
    end: (message, meta = {}) => {
      calls.info.push({ 
        message, 
        meta: { ...meta, type: 'timing', label },
        timestamp: new Date(),
      });
      return 0;
    },
  });

  mockLogger.withCorrelation = () => mockLogger;
  mockLogger.withContext = () => mockLogger;
  mockLogger.child = () => mockLogger;
  mockLogger.event = (eventName, data) => {
    calls.info.push({
      message: `Event: ${eventName}`,
      meta: { type: 'business_event', event: eventName, data },
      timestamp: new Date(),
    });
  };

  // Testing utilities
  mockLogger.getCalls = () => ({ ...calls });
  mockLogger.reset = () => {
    Object.keys(calls).forEach(level => {
      calls[level] = [];
    });
  };

  return mockLogger;
};

// Export factory instance and utilities
module.exports = {
  LoggerFactory,
  loggerFactory,
  requestLogger,
  errorLogger,
  createMockLogger,
  
  // Convenience functions
  createLogger: (name, options) => loggerFactory.create(name, options),
  getLogger: (name) => loggerFactory.get(name),
  createChildLogger: (parentName, context) => loggerFactory.child(parentName, context),
};