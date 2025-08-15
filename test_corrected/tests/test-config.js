/**
 * Test Configuration Setup (London School TDD)
 * Comprehensive test environment configuration with mock management
 */

const path = require('path');

// Environment configuration
const TEST_ENV = process.env.NODE_ENV || 'test';
const IS_CI = Boolean(process.env.CI);
const VERBOSE_LOGGING = process.env.VERBOSE_TEST_LOGS === 'true';

/**
 * Base Jest Configuration
 */
const baseConfig = {
  // Test environment
  testEnvironment: 'node',
  
  // Test file patterns
  testMatch: [
    '<rootDir>/tests/**/*.test.js',
    '<rootDir>/tests/**/*.spec.js'
  ],
  
  // Coverage configuration
  collectCoverage: true,
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/**/*.test.js',
    '!src/**/*.spec.js',
    '!src/config/**',
    '!src/migrations/**'
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html', 'json-summary'],
  coverageThreshold: {
    global: {
      branches: 90,
      functions: 95,
      lines: 95,
      statements: 95
    }
  },
  
  // Module resolution
  moduleNameMapping: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '^@tests/(.*)$': '<rootDir>/tests/$1',
    '^@mocks/(.*)$': '<rootDir>/tests/mocks/$1',
    '^@fixtures/(.*)$': '<rootDir>/tests/fixtures/$1'
  },
  
  // Setup files
  setupFilesAfterEnv: [
    '<rootDir>/tests/setup/jest.setup.js',
    '<rootDir>/tests/setup/mockSetup.js',
    '<rootDir>/tests/setup/customMatchers.js'
  ],
  
  // Test timeout
  testTimeout: IS_CI ? 30000 : 10000,
  
  // Verbose output
  verbose: VERBOSE_LOGGING,
  
  // Parallel execution
  maxWorkers: IS_CI ? 2 : '50%',
  
  // Clear mocks between tests
  clearMocks: true,
  restoreMocks: true,
  resetMocks: false, // Keep mock implementations for London School patterns
  
  // Transform configuration
  transform: {
    '^.+\\.js$': 'babel-jest'
  },
  
  // Module directories
  moduleDirectories: ['node_modules', 'src', 'tests']
};

/**
 * Mock Management Configuration
 */
const mockConfig = {
  // Global mock patterns
  globalMocks: {
    // External services
    './services/emailService': '<rootDir>/tests/mocks/services/emailService.mock.js',
    './services/paymentService': '<rootDir>/tests/mocks/services/paymentService.mock.js',
    './services/shippingService': '<rootDir>/tests/mocks/services/shippingService.mock.js',
    
    // Repositories
    './repositories/userRepository': '<rootDir>/tests/mocks/repositories/userRepository.mock.js',
    './repositories/orderRepository': '<rootDir>/tests/mocks/repositories/orderRepository.mock.js',
    
    // External libraries
    'nodemailer': '<rootDir>/tests/mocks/external/nodemailer.mock.js',
    'stripe': '<rootDir>/tests/mocks/external/stripe.mock.js',
    'axios': '<rootDir>/tests/mocks/external/axios.mock.js'
  },
  
  // Mock factories directory
  mockFactoriesPath: '<rootDir>/tests/mocks/factories',
  
  // Mock reset patterns
  resetPatterns: {
    beforeEach: ['repositories', 'services'],
    beforeAll: ['external', 'config'],
    afterEach: ['state', 'interactions'],
    afterAll: ['connections', 'timers']
  }
};

/**
 * Test Database Configuration
 */
const databaseConfig = {
  // In-memory database for unit tests
  unit: {
    type: 'memory',
    database: ':memory:',
    synchronize: true,
    logging: false,
    entities: ['src/models/**/*.js']
  },
  
  // Test database for integration tests
  integration: {
    type: 'sqlite',
    database: 'test_integration.db',
    synchronize: true,
    logging: VERBOSE_LOGGING,
    entities: ['src/models/**/*.js'],
    migrations: ['src/migrations/**/*.js'],
    cli: {
      migrationsDir: 'src/migrations'
    }
  },
  
  // Docker containers for E2E tests
  e2e: {
    type: 'postgres',
    host: process.env.TEST_DB_HOST || 'localhost',
    port: parseInt(process.env.TEST_DB_PORT) || 5432,
    username: process.env.TEST_DB_USER || 'test_user',
    password: process.env.TEST_DB_PASS || 'test_password',
    database: process.env.TEST_DB_NAME || 'test_e2e',
    synchronize: true,
    logging: false,
    entities: ['src/models/**/*.js']
  }
};

/**
 * Test Categories Configuration
 */
const testCategories = {
  unit: {
    displayName: 'Unit Tests',
    testMatch: ['<rootDir>/tests/unit/**/*.test.js'],
    setupFilesAfterEnv: ['<rootDir>/tests/setup/unit.setup.js'],
    maxWorkers: IS_CI ? 4 : '75%',
    testTimeout: 5000
  },
  
  integration: {
    displayName: 'Integration Tests', 
    testMatch: ['<rootDir>/tests/integration/**/*.test.js'],
    setupFilesAfterEnv: ['<rootDir>/tests/setup/integration.setup.js'],
    maxWorkers: 1, // Sequential for database tests
    testTimeout: 15000
  },
  
  e2e: {
    displayName: 'E2E Tests',
    testMatch: ['<rootDir>/tests/e2e/**/*.test.js'],
    setupFilesAfterEnv: ['<rootDir>/tests/setup/e2e.setup.js'],
    maxWorkers: 1, // Sequential for full system tests
    testTimeout: 30000,
    testEnvironment: '<rootDir>/tests/setup/e2e.environment.js'
  }
};

/**
 * Mock Factory Registry
 */
class MockFactoryRegistry {
  constructor() {
    this.factories = new Map();
    this.instances = new Map();
  }
  
  register(name, factory) {
    this.factories.set(name, factory);
  }
  
  create(name, options = {}) {
    const factory = this.factories.get(name);
    if (!factory) {
      throw new Error(`Mock factory '${name}' not found`);
    }
    
    const instance = factory.create(options);
    this.instances.set(`${name}-${Date.now()}`, instance);
    return instance;
  }
  
  reset() {
    this.instances.forEach(instance => {
      if (instance.reset && typeof instance.reset === 'function') {
        instance.reset();
      }
    });
    this.instances.clear();
  }
}

/**
 * Test Utilities Configuration
 */
const testUtilities = {
  // Mock factory registry
  mockRegistry: new MockFactoryRegistry(),
  
  // Test data builders
  builders: {
    user: require('./fixtures/builders/userBuilder'),
    order: require('./fixtures/builders/orderBuilder'),
    product: require('./fixtures/builders/productBuilder')
  },
  
  // Test helpers
  helpers: {
    database: require('./utils/databaseHelper'),
    api: require('./utils/apiHelper'),
    mock: require('./utils/mockHelper'),
    assertion: require('./utils/assertionHelper')
  },
  
  // Custom matchers
  matchers: require('./utils/customMatchers'),
  
  // Performance monitoring
  performance: {
    enabled: IS_CI,
    thresholds: {
      unit: 1, // 1ms per test
      integration: 100, // 100ms per test
      e2e: 5000 // 5s per test
    }
  }
};

/**
 * CI/CD Integration Configuration
 */
const ciConfig = {
  // Reporter configuration for CI
  reporters: IS_CI ? [
    'default',
    ['jest-junit', {
      outputDirectory: 'test-results',
      outputName: 'junit.xml',
      usePathForSuiteName: true
    }],
    ['jest-html-reporters', {
      publicPath: 'test-results',
      filename: 'report.html',
      expand: true
    }]
  ] : ['default'],
  
  // Parallel execution limits for CI
  maxWorkers: IS_CI ? Math.max(1, Math.floor(require('os').cpus().length / 2)) : '50%',
  
  // Bail configuration
  bail: IS_CI ? 1 : 0,
  
  // Cache configuration
  cache: !IS_CI,
  cacheDirectory: '<rootDir>/.jest-cache',
  
  // Watch configuration
  watchman: !IS_CI,
  watchPathIgnorePatterns: [
    '<rootDir>/node_modules/',
    '<rootDir>/coverage/',
    '<rootDir>/test-results/'
  ]
};

/**
 * Environment-specific Configuration
 */
const environmentConfig = {
  test: {
    ...baseConfig,
    ...ciConfig,
    projects: [
      {
        ...testCategories.unit,
        ...baseConfig
      },
      {
        ...testCategories.integration,
        ...baseConfig
      },
      {
        ...testCategories.e2e,
        ...baseConfig
      }
    ]
  },
  
  development: {
    ...baseConfig,
    collectCoverage: false,
    watchMode: true,
    verbose: true
  },
  
  ci: {
    ...baseConfig,
    ...ciConfig,
    collectCoverage: true,
    coverageReporters: ['lcov', 'json-summary', 'text'],
    maxWorkers: 2,
    bail: 1
  }
};

/**
 * Export Configuration
 */
module.exports = {
  // Main configuration
  ...environmentConfig[TEST_ENV],
  
  // Additional configurations
  mockConfig,
  databaseConfig,
  testCategories,
  testUtilities,
  
  // Helper functions
  getDatabaseConfig: (category) => databaseConfig[category],
  getMockFactory: (name) => testUtilities.mockRegistry.create(name),
  
  // Environment checks
  isCI: IS_CI,
  isVerbose: VERBOSE_LOGGING,
  environment: TEST_ENV,
  
  // Paths
  paths: {
    root: path.resolve(__dirname, '..'),
    src: path.resolve(__dirname, '../src'),
    tests: path.resolve(__dirname, '.'),
    mocks: path.resolve(__dirname, 'mocks'),
    fixtures: path.resolve(__dirname, 'fixtures'),
    utils: path.resolve(__dirname, 'utils'),
    coverage: path.resolve(__dirname, '../coverage'),
    reports: path.resolve(__dirname, '../test-results')
  }
};