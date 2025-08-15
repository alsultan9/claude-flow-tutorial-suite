/**
 * Jest Setup File
 * Global test configuration and utilities for London School TDD
 */

const { createMockLogger } = require('../../src/shared/logger');
const { createError } = require('../../src/shared/errors');

// Set test environment
process.env.NODE_ENV = 'test';

// Global test timeout
jest.setTimeout(10000);

// Mock external dependencies by default
jest.mock('nodemailer', () => ({
  createTransporter: jest.fn(() => ({
    sendMail: jest.fn().mockResolvedValue({ messageId: 'mock-message-id' }),
    verify: jest.fn().mockResolvedValue(true),
  })),
}));

jest.mock('bcrypt', () => ({
  hash: jest.fn().mockResolvedValue('mock-hashed-password'),
  compare: jest.fn().mockResolvedValue(true),
}));

// Global test utilities
global.testUtils = {
  // Create mock logger for tests
  createMockLogger,
  
  // Create error utilities
  createError,
  
  // Mock database connection
  createMockDatabase: () => ({
    query: jest.fn(),
    close: jest.fn(),
  }),
  
  // Generate test IDs
  generateTestId: (prefix = 'test') => `${prefix}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
  
  // Create test user data
  createTestUser: (overrides = {}) => ({
    id: global.testUtils.generateTestId('user'),
    email: 'test@example.com',
    password: 'hashedPassword123',
    name: 'Test User',
    role: 'user',
    status: 'active',
    verified: true,
    profile: {
      firstName: 'Test',
      lastName: 'User',
      phone: null,
      address: null,
      dateOfBirth: null,
      preferences: {
        notifications: true,
        theme: 'light',
        language: 'en',
      },
    },
    permissions: ['read', 'write'],
    metadata: {},
    createdAt: new Date(),
    updatedAt: new Date(),
    lastLoginAt: null,
    ...overrides,
  }),
  
  // Async test helper
  asyncTest: (fn) => {
    return async () => {
      try {
        await fn();
      } catch (error) {
        console.error('Async test failed:', error);
        throw error;
      }
    };
  },
  
  // Wait helper
  wait: (ms) => new Promise(resolve => setTimeout(resolve, ms)),
  
  // Mock Express request object
  createMockRequest: (overrides = {}) => ({
    body: {},
    params: {},
    query: {},
    headers: {},
    cookies: {},
    ip: '127.0.0.1',
    method: 'GET',
    path: '/test',
    url: '/test',
    originalUrl: '/test',
    get: jest.fn((header) => overrides.headers?.[header.toLowerCase()]),
    user: null,
    correlationId: 'test-correlation-id',
    logger: createMockLogger(),
    ...overrides,
  }),
  
  // Mock Express response object
  createMockResponse: () => {
    const res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
      send: jest.fn().mockReturnThis(),
      cookie: jest.fn().mockReturnThis(),
      clearCookie: jest.fn().mockReturnThis(),
      setHeader: jest.fn().mockReturnThis(),
      set: jest.fn().mockReturnThis(),
      end: jest.fn().mockReturnThis(),
      statusCode: 200,
      headersSent: false,
      locals: {},
    };
    
    // Mock response.on method
    res.on = jest.fn((event, callback) => {
      if (event === 'finish') {
        // Simulate response finished
        setTimeout(callback, 0);
      }
      return res;
    });
    
    return res;
  },
  
  // Mock Express next function
  createMockNext: () => jest.fn(),
};

// Custom Jest matchers for better assertions
expect.extend({
  // Matcher for checking if error is instance of custom error
  toBeCustomError(received, expectedCode = null) {
    const pass = received && 
                 received.name && 
                 received.name.includes('Error') &&
                 received.statusCode &&
                 received.code &&
                 (expectedCode === null || received.code === expectedCode);
    
    if (pass) {
      return {
        message: () => `expected ${received} not to be a custom error${expectedCode ? ` with code ${expectedCode}` : ''}`,
        pass: true,
      };
    } else {
      return {
        message: () => `expected ${received} to be a custom error${expectedCode ? ` with code ${expectedCode}` : ''}`,
        pass: false,
      };
    }
  },
  
  // Matcher for checking mock call order (London School TDD)
  toHaveBeenCalledBefore(received, other) {
    if (!jest.isMockFunction(received)) {
      throw new Error('Expected a mock function');
    }
    
    if (!jest.isMockFunction(other)) {
      throw new Error('Expected comparison to be a mock function');
    }
    
    const receivedCalls = received.mock.invocationCallOrder;
    const otherCalls = other.mock.invocationCallOrder;
    
    if (receivedCalls.length === 0) {
      return {
        message: () => 'Expected mock function to have been called',
        pass: false,
      };
    }
    
    if (otherCalls.length === 0) {
      return {
        message: () => 'Expected comparison mock function to have been called',
        pass: false,
      };
    }
    
    const lastReceivedCall = Math.max(...receivedCalls);
    const firstOtherCall = Math.min(...otherCalls);
    
    const pass = lastReceivedCall < firstOtherCall;
    
    if (pass) {
      return {
        message: () => `expected ${received.getMockName()} not to have been called before ${other.getMockName()}`,
        pass: true,
      };
    } else {
      return {
        message: () => `expected ${received.getMockName()} to have been called before ${other.getMockName()}`,
        pass: false,
      };
    }
  },
  
  // Matcher for checking mock interactions (London School verification)
  toHaveBeenCalledWithExactly(received, ...expectedArgs) {
    if (!jest.isMockFunction(received)) {
      throw new Error('Expected a mock function');
    }
    
    const calls = received.mock.calls;
    const pass = calls.some(call => 
      call.length === expectedArgs.length &&
      call.every((arg, index) => this.equals(arg, expectedArgs[index]))
    );
    
    if (pass) {
      return {
        message: () => `expected mock function not to have been called with exactly [${expectedArgs.join(', ')}]`,
        pass: true,
      };
    } else {
      return {
        message: () => `expected mock function to have been called with exactly [${expectedArgs.join(', ')}]`,
        pass: false,
      };
    }
  },
  
  // Matcher for checking object structure without specific values
  toMatchStructure(received, expected) {
    const checkStructure = (obj, structure) => {
      if (typeof structure !== 'object' || structure === null) {
        return typeof obj === typeof structure;
      }
      
      if (Array.isArray(structure)) {
        return Array.isArray(obj) && 
               obj.length === structure.length &&
               obj.every((item, index) => checkStructure(item, structure[index]));
      }
      
      const structureKeys = Object.keys(structure);
      const objKeys = Object.keys(obj);
      
      return structureKeys.every(key => objKeys.includes(key)) &&
             structureKeys.every(key => checkStructure(obj[key], structure[key]));
    };
    
    const pass = checkStructure(received, expected);
    
    if (pass) {
      return {
        message: () => `expected object not to match structure`,
        pass: true,
      };
    } else {
      return {
        message: () => `expected object to match structure`,
        pass: false,
      };
    }
  },
});

// Global setup and teardown
beforeEach(() => {
  // Clear all mocks before each test
  jest.clearAllMocks();
  
  // Reset any global state
  if (global.testState) {
    global.testState = {};
  }
});

afterEach(() => {
  // Cleanup after each test
  jest.restoreAllMocks();
});

// Handle unhandled promise rejections in tests
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Promise Rejection in test:', reason);
  throw reason;
});

// Console override for cleaner test output
const originalConsoleError = console.error;
console.error = (...args) => {
  // Only show errors that aren't expected test errors
  if (!args.some(arg => typeof arg === 'string' && arg.includes('Test Error'))) {
    originalConsoleError.apply(console, args);
  }
};