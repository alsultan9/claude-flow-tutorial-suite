# Mock Implementation Patterns (London School TDD)

## Core Mock Patterns

### 1. Interface Mock Pattern

Define collaborator contracts through mock interfaces before implementation exists.

```javascript
// Define the contract through mock expectations
describe('UserService', () => {
  let mockUserRepository;
  let mockEmailService;
  let userService;
  
  beforeEach(() => {
    // Define repository contract through mock
    mockUserRepository = {
      findByEmail: jest.fn(),
      save: jest.fn(),
      delete: jest.fn()
    };
    
    // Define email service contract through mock
    mockEmailService = {
      sendWelcomeEmail: jest.fn(),
      sendPasswordReset: jest.fn()
    };
    
    userService = new UserService(mockUserRepository, mockEmailService);
  });
  
  it('should coordinate user registration workflow', async () => {
    // Arrange: Set up mock expectations
    const userData = { email: 'test@example.com', password: 'password123' };
    const savedUser = { id: '123', ...userData };
    
    mockUserRepository.findByEmail.mockResolvedValue(null);
    mockUserRepository.save.mockResolvedValue(savedUser);
    mockEmailService.sendWelcomeEmail.mockResolvedValue(true);
    
    // Act: Execute the behavior
    const result = await userService.register(userData);
    
    // Assert: Verify the collaboration
    expect(mockUserRepository.findByEmail).toHaveBeenCalledWith(userData.email);
    expect(mockUserRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({ email: userData.email })
    );
    expect(mockEmailService.sendWelcomeEmail).toHaveBeenCalledWith(savedUser.id);
    expect(result.success).toBe(true);
  });
});
```

### 2. Mock Factory Pattern

Create reusable mock factories for consistent mock creation across tests.

```javascript
// tests/mocks/factories/userRepositoryMockFactory.js
export class UserRepositoryMockFactory {
  static create(overrides = {}) {
    return {
      findByEmail: jest.fn(),
      findById: jest.fn(),
      save: jest.fn(),
      delete: jest.fn(),
      findAll: jest.fn(),
      update: jest.fn(),
      ...overrides
    };
  }
  
  static createWithSuccessfulSave(savedUser) {
    return this.create({
      save: jest.fn().mockResolvedValue(savedUser)
    });
  }
  
  static createWithExistingUser(existingUser) {
    return this.create({
      findByEmail: jest.fn().mockResolvedValue(existingUser)
    });
  }
  
  static createWithNotFound() {
    return this.create({
      findByEmail: jest.fn().mockResolvedValue(null),
      findById: jest.fn().mockResolvedValue(null)
    });
  }
}
```

### 3. Conversation Testing Pattern

Focus on verifying the conversation between objects rather than their internal state.

```javascript
describe('OrderService conversation patterns', () => {
  let mockInventory;
  let mockPayment;
  let mockShipping;
  let mockNotification;
  let orderService;
  
  beforeEach(() => {
    mockInventory = InventoryMockFactory.create();
    mockPayment = PaymentMockFactory.create();
    mockShipping = ShippingMockFactory.create();
    mockNotification = NotificationMockFactory.create();
    
    orderService = new OrderService(
      mockInventory,
      mockPayment, 
      mockShipping,
      mockNotification
    );
  });
  
  it('should orchestrate complete order processing conversation', async () => {
    // Arrange: Set up the conversation expectations
    const order = OrderBuilder.create().withItems(['item1', 'item2']).build();
    
    mockInventory.reserve.mockResolvedValue({ success: true, reservation: 'res123' });
    mockPayment.charge.mockResolvedValue({ success: true, transaction: 'txn456' });
    mockShipping.schedule.mockResolvedValue({ success: true, tracking: 'ship789' });
    mockNotification.sendConfirmation.mockResolvedValue(true);
    
    // Act: Execute the orchestration
    await orderService.processOrder(order);
    
    // Assert: Verify the conversation sequence
    expect(mockInventory.reserve).toHaveBeenCalledWith(order.items);
    expect(mockPayment.charge).toHaveBeenCalledWith(order.total, order.paymentMethod);
    expect(mockShipping.schedule).toHaveBeenCalledWith(
      expect.objectContaining({
        orderId: order.id,
        items: order.items
      })
    );
    expect(mockNotification.sendConfirmation).toHaveBeenCalledWith(
      order.customerId,
      expect.objectContaining({ orderId: order.id })
    );
    
    // Verify conversation order using jest-when or custom matchers
    expect(mockInventory.reserve).toHaveBeenCalledBefore(mockPayment.charge);
    expect(mockPayment.charge).toHaveBeenCalledBefore(mockShipping.schedule);
    expect(mockShipping.schedule).toHaveBeenCalledBefore(mockNotification.sendConfirmation);
  });
});
```

### 4. Error Conversation Pattern

Test error handling workflows through mock failures.

```javascript
describe('OrderService error handling conversations', () => {
  it('should handle inventory reservation failure gracefully', async () => {
    // Arrange: Set up failure scenario
    const order = OrderBuilder.create().build();
    const inventoryError = new Error('Insufficient inventory');
    
    mockInventory.reserve.mockRejectedValue(inventoryError);
    
    // Act & Assert: Verify error handling conversation
    await expect(orderService.processOrder(order)).rejects.toThrow('Insufficient inventory');
    
    // Verify that dependent services were not called
    expect(mockInventory.reserve).toHaveBeenCalled();
    expect(mockPayment.charge).not.toHaveBeenCalled();
    expect(mockShipping.schedule).not.toHaveBeenCalled();
    expect(mockNotification.sendConfirmation).not.toHaveBeenCalled();
  });
  
  it('should rollback inventory reservation when payment fails', async () => {
    // Arrange: Set up partial success with payment failure
    const order = OrderBuilder.create().build();
    const reservationResult = { success: true, reservation: 'res123' };
    const paymentError = new Error('Payment declined');
    
    mockInventory.reserve.mockResolvedValue(reservationResult);
    mockInventory.releaseReservation.mockResolvedValue(true);
    mockPayment.charge.mockRejectedValue(paymentError);
    
    // Act & Assert
    await expect(orderService.processOrder(order)).rejects.toThrow('Payment declined');
    
    // Verify compensation conversation
    expect(mockInventory.reserve).toHaveBeenCalled();
    expect(mockPayment.charge).toHaveBeenCalled();
    expect(mockInventory.releaseReservation).toHaveBeenCalledWith('res123');
    expect(mockShipping.schedule).not.toHaveBeenCalled();
  });
});
```

### 5. Mock State Management Pattern

Manage mock state across complex test scenarios.

```javascript
class MockStateManager {
  constructor() {
    this.mocks = new Map();
    this.interactions = [];
  }
  
  registerMock(name, mockObject) {
    // Wrap mock methods to track interactions
    Object.keys(mockObject).forEach(method => {
      if (typeof mockObject[method] === 'function') {
        const originalMock = mockObject[method];
        mockObject[method] = jest.fn((...args) => {
          this.interactions.push({ mock: name, method, args, timestamp: Date.now() });
          return originalMock.apply(mockObject, args);
        });
      }
    });
    
    this.mocks.set(name, mockObject);
    return mockObject;
  }
  
  getMock(name) {
    return this.mocks.get(name);
  }
  
  verifyInteractionOrder(expectedOrder) {
    const actualOrder = this.interactions.map(i => `${i.mock}.${i.method}`);
    expect(actualOrder).toEqual(expectedOrder);
  }
  
  reset() {
    this.interactions = [];
    this.mocks.forEach(mock => {
      Object.values(mock).forEach(method => {
        if (jest.isMockFunction(method)) {
          method.mockReset();
        }
      });
    });
  }
  
  getInteractionHistory() {
    return [...this.interactions];
  }
}

// Usage in tests
describe('Complex workflow with state management', () => {
  let stateManager;
  let workflowService;
  
  beforeEach(() => {
    stateManager = new MockStateManager();
    
    const userRepo = stateManager.registerMock('userRepo', UserRepositoryMockFactory.create());
    const emailService = stateManager.registerMock('emailService', EmailServiceMockFactory.create());
    const auditLog = stateManager.registerMock('auditLog', AuditLogMockFactory.create());
    
    workflowService = new UserWorkflowService(userRepo, emailService, auditLog);
  });
  
  afterEach(() => {
    stateManager.reset();
  });
  
  it('should execute user onboarding workflow in correct order', async () => {
    // Arrange
    const userData = UserBuilder.create().build();
    stateManager.getMock('userRepo').save.mockResolvedValue({ ...userData, id: '123' });
    stateManager.getMock('emailService').sendWelcome.mockResolvedValue(true);
    stateManager.getMock('auditLog').log.mockResolvedValue(true);
    
    // Act
    await workflowService.onboardUser(userData);
    
    // Assert: Verify interaction order
    stateManager.verifyInteractionOrder([
      'auditLog.log',      // Log start
      'userRepo.save',     // Save user
      'emailService.sendWelcome', // Send email
      'auditLog.log'       // Log completion
    ]);
  });
});
```

### 6. Contract Testing Pattern

Ensure mocks accurately represent real implementations.

```javascript
// Contract definition
class UserRepositoryContract {
  static getContractTests() {
    return {
      save: {
        validInput: { email: 'test@example.com', name: 'Test User' },
        expectedOutput: expect.objectContaining({ id: expect.any(String) }),
        errorCases: [
          { input: null, error: 'Invalid user data' },
          { input: { email: 'invalid-email' }, error: 'Invalid email format' }
        ]
      },
      findByEmail: {
        validInput: 'test@example.com',
        expectedOutput: expect.objectContaining({ email: 'test@example.com' }),
        notFoundOutput: null
      }
    };
  }
  
  static verifyImplementation(implementation) {
    const contract = this.getContractTests();
    
    describe('UserRepository contract verification', () => {
      Object.entries(contract).forEach(([method, spec]) => {
        it(`should satisfy contract for ${method}`, async () => {
          if (spec.validInput && spec.expectedOutput) {
            const result = await implementation[method](spec.validInput);
            expect(result).toEqual(spec.expectedOutput);
          }
          
          if (spec.errorCases) {
            spec.errorCases.forEach(async ({ input, error }) => {
              await expect(implementation[method](input)).rejects.toThrow(error);
            });
          }
        });
      });
    });
  }
}

// Mock verification
describe('UserRepository mock contract compliance', () => {
  let mockRepo;
  
  beforeEach(() => {
    mockRepo = UserRepositoryMockFactory.create();
    // Set up mock to satisfy contract
    mockRepo.save.mockImplementation(async (userData) => {
      if (!userData) throw new Error('Invalid user data');
      if (!userData.email?.includes('@')) throw new Error('Invalid email format');
      return { ...userData, id: '123', createdAt: new Date() };
    });
    
    mockRepo.findByEmail.mockImplementation(async (email) => {
      if (email === 'test@example.com') {
        return { id: '123', email, name: 'Test User' };
      }
      return null;
    });
  });
  
  UserRepositoryContract.verifyImplementation(mockRepo);
});
```

### 7. Mock Lifecycle Management Pattern

Manage complex mock setups and teardowns.

```javascript
class MockLifecycleManager {
  constructor() {
    this.mockSets = new Map();
    this.cleanupTasks = [];
  }
  
  createMockSet(name, factory) {
    const mockSet = factory();
    this.mockSets.set(name, mockSet);
    return mockSet;
  }
  
  configureMockSet(name, configuration) {
    const mockSet = this.mockSets.get(name);
    if (!mockSet) throw new Error(`Mock set ${name} not found`);
    
    Object.entries(configuration).forEach(([method, behavior]) => {
      if (mockSet[method]) {
        mockSet[method].mockImplementation(behavior);
      }
    });
    
    return mockSet;
  }
  
  addCleanupTask(task) {
    this.cleanupTasks.push(task);
  }
  
  cleanup() {
    this.cleanupTasks.forEach(task => task());
    this.cleanupTasks = [];
    
    this.mockSets.forEach(mockSet => {
      Object.values(mockSet).forEach(mock => {
        if (jest.isMockFunction(mock)) {
          mock.mockReset();
        }
      });
    });
    
    this.mockSets.clear();
  }
}

// Usage
describe('Complex service integration', () => {
  let lifecycleManager;
  let serviceUnderTest;
  
  beforeEach(() => {
    lifecycleManager = new MockLifecycleManager();
    
    // Create coordinated mock sets
    const persistenceLayer = lifecycleManager.createMockSet('persistence', () => ({
      userRepo: UserRepositoryMockFactory.create(),
      orderRepo: OrderRepositoryMockFactory.create(),
      transactionManager: TransactionMockFactory.create()
    }));
    
    const externalServices = lifecycleManager.createMockSet('external', () => ({
      paymentGateway: PaymentGatewayMockFactory.create(),
      shippingProvider: ShippingProviderMockFactory.create(),
      emailService: EmailServiceMockFactory.create()
    }));
    
    serviceUnderTest = new ComplexBusinessService(persistenceLayer, externalServices);
  });
  
  afterEach(() => {
    lifecycleManager.cleanup();
  });
  
  it('should handle complex business workflow', async () => {
    // Configure mock behaviors for this specific scenario
    lifecycleManager.configureMockSet('persistence', {
      userRepo: {
        findById: async (id) => UserBuilder.create().withId(id).build()
      },
      orderRepo: {
        save: async (order) => ({ ...order, id: 'order123' })
      }
    });
    
    lifecycleManager.configureMockSet('external', {
      paymentGateway: {
        charge: async () => ({ success: true, transactionId: 'txn456' })
      },
      emailService: {
        sendConfirmation: async () => true
      }
    });
    
    // Execute test
    const result = await serviceUnderTest.processComplexWorkflow({
      userId: 'user123',
      orderData: { items: ['item1'] }
    });
    
    expect(result.success).toBe(true);
  });
});
```

## Mock Verification Patterns

### 1. Interaction Verification
```javascript
// Verify specific method calls
expect(mockService.method).toHaveBeenCalledWith(expectedArgs);
expect(mockService.method).toHaveBeenCalledTimes(1);
expect(mockService.method).not.toHaveBeenCalled();

// Verify call order
expect(mockServiceA.method).toHaveBeenCalledBefore(mockServiceB.method);
```

### 2. Argument Matching
```javascript
// Exact matching
expect(mockService.save).toHaveBeenCalledWith({
  id: '123',
  name: 'Test User'
});

// Partial matching
expect(mockService.save).toHaveBeenCalledWith(
  expect.objectContaining({
    email: 'test@example.com'
  })
);

// Type matching
expect(mockService.log).toHaveBeenCalledWith(
  expect.any(String),
  expect.any(Date)
);

// Custom matchers
expect(mockService.notify).toHaveBeenCalledWith(
  expect.stringMatching(/user-\d+/)
);
```

### 3. Mock Return Value Patterns
```javascript
// Simple return values
mockService.getData.mockReturnValue(testData);
mockService.getDataAsync.mockResolvedValue(testData);

// Conditional returns
mockService.findUser
  .mockReturnValueOnce(null)
  .mockReturnValueOnce(existingUser);

// Dynamic returns based on input
mockService.calculate.mockImplementation((input) => {
  return input * 2;
});
```

These patterns provide a comprehensive foundation for implementing London School TDD with effective mock-driven development practices.