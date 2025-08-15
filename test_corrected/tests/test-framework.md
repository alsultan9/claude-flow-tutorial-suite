# TDD Testing Framework Architecture (London School)

## Overview

This testing framework implements the London School (mockist) approach to Test-Driven Development, emphasizing outside-in development with comprehensive mock usage for isolation and behavior verification.

## Architecture Principles

### 1. Outside-In Development
- Start with acceptance tests (outside)
- Drive down to implementation details (inside)
- Use mocks to define contracts before implementation
- Focus on behavior over state verification

### 2. Mock-First Approach
- Mock all external dependencies
- Define collaborator contracts through mock expectations
- Isolate units completely for true unit testing
- Verify interactions rather than internal state

### 3. Test Pyramid Structure

```
    /\     E2E Tests (Few, Slow, Broad)
   /  \    
  /____\   Integration Tests (Some, Medium, Focused)
 /______\  
/__________\ Unit Tests (Many, Fast, Isolated)
```

## Framework Components

### 1. Test Configuration Layer
- Environment-specific configurations
- Mock factory setup
- Test database management
- CI/CD integration settings

### 2. Mock Management System
- Centralized mock definitions
- Mock factory patterns
- Contract verification utilities
- Mock state management

### 3. Test Utilities
- Common test helpers
- Mock assertion libraries
- Test data builders
- Custom matchers

### 4. Test Categories

#### Unit Tests (`/tests/unit/`)
- **Purpose**: Test individual units in isolation
- **Approach**: Mock all dependencies
- **Focus**: Behavior verification through interactions
- **Speed**: Very fast (<1ms per test)

#### Integration Tests (`/tests/integration/`)
- **Purpose**: Test component interactions
- **Approach**: Mock external services, use real internal components
- **Focus**: Contract verification between components
- **Speed**: Medium (10-100ms per test)

#### End-to-End Tests (`/tests/e2e/`)
- **Purpose**: Test complete user workflows
- **Approach**: Use real services with controlled test data
- **Focus**: Business value verification
- **Speed**: Slow (100ms-10s per test)

## Test Naming Conventions

### File Naming
```
// Unit tests
src/services/userService.js → tests/unit/services/userService.test.js

// Integration tests
tests/integration/api/userRoutes.integration.test.js

// E2E tests
tests/e2e/workflows/userRegistration.e2e.test.js
```

### Test Case Naming
```javascript
describe('UserService', () => {
  describe('register', () => {
    it('should save user to repository when valid data provided', () => {
      // Test implementation
    });
    
    it('should send welcome email after successful registration', () => {
      // Test implementation
    });
    
    it('should throw validation error when email already exists', () => {
      // Test implementation
    });
  });
});
```

## Mock Strategies by Component Type

### Controllers
- Mock all service dependencies
- Verify service method calls with correct parameters
- Test HTTP response formatting
- Mock authentication middleware

### Services
- Mock repository dependencies
- Mock external API clients
- Verify business logic orchestration
- Test error handling workflows

### Repositories
- Mock database connections
- Test query building and execution
- Verify data transformation
- Mock transaction management

### Middleware
- Mock request/response objects
- Test request transformation
- Verify error handling
- Mock authentication providers

## Test Data Management

### 1. Test Fixtures
- Reusable test data objects
- Factory patterns for data generation
- Environment-specific data sets
- Version-controlled test scenarios

### 2. Mock Data Builders
```javascript
class UserBuilder {
  constructor() {
    this.user = {
      id: '123',
      email: 'test@example.com',
      name: 'Test User',
      createdAt: new Date()
    };
  }
  
  withEmail(email) {
    this.user.email = email;
    return this;
  }
  
  withId(id) {
    this.user.id = id;
    return this;
  }
  
  build() {
    return { ...this.user };
  }
}
```

### 3. Mock State Management
- Isolated mock state per test
- Automatic mock reset between tests
- Shared mock configurations
- Mock interaction verification

## CI/CD Integration

### 1. Test Pipeline Stages
```yaml
test_pipeline:
  - stage: unit_tests
    parallel: true
    timeout: 5m
  - stage: integration_tests
    depends_on: unit_tests
    timeout: 10m
  - stage: e2e_tests
    depends_on: integration_tests
    timeout: 20m
```

### 2. Coverage Requirements
- Unit Tests: 95% line coverage, 90% branch coverage
- Integration Tests: Critical paths covered
- E2E Tests: Main user workflows covered

### 3. Quality Gates
- All tests must pass
- Coverage thresholds met
- No test flakiness detected
- Performance benchmarks maintained

## Development Workflow

### 1. Red-Green-Refactor Cycle
1. **Red**: Write failing test with mocks defining expected behavior
2. **Green**: Implement minimal code to pass the test
3. **Refactor**: Improve code while maintaining test passage

### 2. Mock-Driven Design
1. Define collaborator interfaces through mocks
2. Implement just enough to satisfy mock contracts
3. Verify interactions match expected behavior
4. Refactor with confidence using mock contracts

### 3. Outside-In Development
1. Start with acceptance test describing user goal
2. Identify required collaborations through mocks
3. Drive down to implementation layer by layer
4. Each layer uses mocks to define next layer contracts

## Testing Tools and Libraries

### Core Testing Framework
- **Jest**: Test runner and assertion library
- **Supertest**: HTTP endpoint testing
- **Sinon**: Advanced mocking and stubbing
- **Test Containers**: Integration test environments

### Mock Management
- **jest.fn()**: Function mocking
- **jest.mock()**: Module mocking
- **MSW**: API mocking for integration tests
- **Custom mock factories**: Domain-specific mocks

### Assertion Libraries
- **Jest matchers**: Standard assertions
- **jest-extended**: Additional matchers
- **Custom matchers**: Domain-specific assertions

## Best Practices

### 1. Mock Design
- Keep mocks simple and focused
- Mock at the boundary of your system
- Verify interactions, not implementations
- Use mocks to define contracts

### 2. Test Organization
- One test class per production class
- Group related tests with describe blocks
- Use clear, descriptive test names
- Keep tests independent and isolated

### 3. Test Maintenance
- Update tests when behavior changes
- Remove tests for deleted functionality
- Refactor tests alongside production code
- Keep test code clean and readable

### 4. Error Testing
- Test happy paths and error conditions
- Verify error messages and types
- Test error propagation through layers
- Mock error conditions comprehensively

## Metrics and Monitoring

### 1. Test Metrics
- Test execution time
- Coverage percentages
- Test failure rates
- Mock verification success

### 2. Quality Indicators
- Test-to-code ratio
- Mock usage patterns
- Test maintenance overhead
- Bug detection rate

### 3. Performance Monitoring
- Test suite execution time
- Individual test performance
- Mock setup/teardown overhead
- CI/CD pipeline efficiency

This framework provides a solid foundation for London School TDD implementation with comprehensive mock-driven development patterns.