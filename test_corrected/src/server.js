#!/usr/bin/env node
/**
 * Server Entry Point
 * Main entry point for starting the SPARC application server
 */

const { startServer } = require('./app');
const { config } = require('./shared/config');
const { createLogger } = require('./shared/logger');

/**
 * Start the application server
 */
async function main() {
  try {
    // Load configuration
    const appConfig = config.load();
    
    // Create logger
    const logger = createLogger('server', {
      level: appConfig.logging.level,
    });
    
    logger.info('Starting SPARC Application Server', {
      nodeVersion: process.version,
      environment: appConfig.server.env,
      pid: process.pid,
    });
    
    // Start server
    const { server, port, host } = await startServer({
      logger,
      port: process.env.PORT || appConfig.server.port,
      host: process.env.HOST || appConfig.server.host,
    });
    
    logger.info('Server startup completed', {
      port,
      host,
      environment: appConfig.server.env,
      urls: [
        `http://${host}:${port}`,
        `http://${host}:${port}/health`,
        `http://${host}:${port}/api/v1/users`,
      ],
    });
    
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

// Start the server if this file is run directly
if (require.main === module) {
  main();
}

module.exports = { main };