# SPARC Implementation Foundation

A comprehensive implementation foundation following SPARC methodology with Test-Driven Development (London School) and hexagonal architecture patterns.

## 🎯 Implementation Overview

This project demonstrates a complete implementation foundation with:

- **Hexagonal Architecture**: Clean separation between domain, application, infrastructure, and presentation layers
- **London School TDD**: Mock-first, outside-in development with behavior verification
- **Domain-Driven Design**: Rich domain models with business logic and invariants
- **SPARC Methodology**: Systematic development approach (Specification → Pseudocode → Architecture → Refinement → Completion)

## 🏗️ Architecture

### Hexagonal Architecture Layers

```
src/
├── domain/              # Domain models and business logic
│   └── user/           # User aggregate with domain logic
├── application/        # Application services and use cases
│   └── services/       # Service orchestration layer
├── infrastructure/     # External service adapters
│   ├── repositories/   # Data access implementations
│   └── external/       # External service integrations
├── presentation/       # HTTP controllers and routes
│   ├── controllers/    # REST API controllers
│   ├── middleware/     # Authentication and validation
│   └── routes/         # Route definitions
└── shared/            # Common utilities and configuration
    ├── config/        # Environment-safe configuration
    ├── errors/        # Custom error handling
    ├── logger/        # Structured logging
    └── utils/         # Utility services
```

## 🧪 Testing Framework (London School TDD)

### Test Structure
```
tests/
├── unit/              # Isolated unit tests with mocks
├── integration/       # Component integration tests
├── e2e/              # End-to-end workflow tests
├── fixtures/         # Test data builders
│   └── builders/     # Domain object builders
├── mocks/           # Mock implementations
│   └── factories/    # Mock factory patterns
└── utils/           # Test utilities and matchers
```

### Key Features

- **Mock-First Development**: All dependencies mocked for true unit isolation
- **Behavior Verification**: Tests verify interactions, not implementation
- **Test Data Builders**: Consistent test data generation with Builder pattern
- **Custom Matchers**: Domain-specific Jest matchers for better assertions

## 🚀 Core Components Implemented

### 1. User Domain Model (`src/domain/user/User.js`)
- Rich domain model with business rules
- Value objects (Email, Password, UserProfile)
- Domain events for business state changes
- Comprehensive validation and invariants

### 2. User Service (`src/application/services/UserService.js`)
- Application layer orchestration
- Business workflow coordination
- Dependency injection with interfaces
- Error handling and logging

### 3. Repository Pattern (`src/infrastructure/repositories/UserRepository.js`)
- Interface-based repository abstraction
- PostgreSQL and In-Memory implementations
- Query building and data mapping
- Error handling and logging

### 4. Authentication System (`src/presentation/middleware/authMiddleware.js`)
- JWT token validation and generation
- Role-based access control (RBAC)
- Permission-based authorization
- Rate limiting and security features

### 5. Configuration Management (`src/shared/config/index.js`)
- Environment-safe configuration loading
- Schema validation with Zod
- Feature flags and runtime configuration
- Production security validations

### 6. Error Handling (`src/shared/errors/index.js`)
- Custom error hierarchies
- HTTP status code mapping
- Structured error responses
- Express error handling middleware

## 🛠️ Implementation Patterns

### Dependency Injection
```javascript
class UserService {
  constructor(userRepository, emailService, hashingService, auditLog) {
    this.userRepository = userRepository;
    this.emailService = emailService;
    this.hashingService = hashingService;
    this.auditLog = auditLog;
  }
}
```

### Domain Events
```javascript
// Domain model emits events
user.changeEmail(newEmail);
user.addDomainEvent('user.email_changed', {
  userId: this.id,
  oldEmail,
  newEmail: this.email.value,
});
```

### Repository Interface
```javascript
class IUserRepository {
  async findById(id) { throw new Error('Method not implemented'); }
  async findByEmail(email) { throw new Error('Method not implemented'); }
  async save(userData) { throw new Error('Method not implemented'); }
}
```

### Mock-Driven Testing
```javascript
describe('UserService', () => {
  let userService;
  let mockUserRepository;
  let mockEmailService;

  beforeEach(() => {
    mockUserRepository = UserRepositoryMockFactory.create();
    mockEmailService = EmailServiceMockFactory.create();
    userService = new UserService(mockUserRepository, mockEmailService);
  });

  it('should orchestrate complete user registration workflow', async () => {
    // Arrange: Define mock expectations
    mockUserRepository.findByEmail.mockResolvedValue(null);
    mockUserRepository.save.mockResolvedValue(savedUser);
    
    // Act: Execute the workflow
    const result = await userService.register(userData);
    
    // Assert: Verify interactions
    expect(mockUserRepository.findByEmail).toHaveBeenCalledWith(userData.email);
    expect(mockUserRepository.save).toHaveBeenCalledWith(expectedUserData);
  });
});
```

## 🔧 Configuration

### Environment Variables
Copy `.env.example` to `.env` and configure:

```bash
# Server
PORT=3000
NODE_ENV=development

# Database
DB_TYPE=postgres
DB_HOST=localhost
DB_PORT=5432
DB_NAME=sparc_app
DB_USERNAME=postgres
DB_PASSWORD=password

# Authentication
JWT_SECRET=your-super-secure-jwt-secret-key-min-32-chars
BCRYPT_SALT_ROUNDS=12

# Email
EMAIL_PROVIDER=smtp
EMAIL_FROM=noreply@example.com
SMTP_HOST=localhost
SMTP_PORT=587
```

### Feature Flags
Control functionality through environment variables:

```bash
FEATURE_USER_REGISTRATION=true
FEATURE_EMAIL_VERIFICATION=true
FEATURE_PASSWORD_RESET=true
FEATURE_AUDIT_LOGGING=true
```

## 📚 API Documentation

### Core Endpoints

#### User Registration
```http
POST /api/v1/users/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "name": "John Doe",
  "profile": {
    "firstName": "John",
    "lastName": "Doe"
  }
}
```

#### User Authentication
```http
POST /api/v1/users/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

#### Get User Profile
```http
GET /api/v1/users/profile
Authorization: Bearer <jwt-token>
```

#### Update Profile
```http
PUT /api/v1/users/profile
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "name": "John Updated",
  "profile": {
    "phone": "555-0123",
    "preferences": {
      "theme": "dark",
      "notifications": false
    }
  }
}
```

## 🧪 Running Tests

### All Tests
```bash
npm test
```

### Unit Tests (London School TDD)
```bash
npm run test:unit
```

### Integration Tests
```bash
npm run test:integration
```

### End-to-End Tests
```bash
npm run test:e2e
```

### Test Coverage
```bash
npm run test:coverage
```

## 🚀 Development

### Start Development Server
```bash
npm run dev
```

### Run Linting
```bash
npm run lint
npm run lint:fix
```

### SPARC Commands
```bash
# List available SPARC modes
npm run sparc:modes

# Run TDD workflow
npm run sparc:tdd "user authentication"

# Run development mode
npm run sparc:dev "implement user registration"
```

## 📋 Implementation Status

### ✅ Completed Components

1. **Configuration Management**
   - Environment-safe configuration loading
   - Schema validation with Zod
   - Production security validations

2. **Error Handling System**
   - Custom error hierarchies
   - HTTP status code mapping
   - Express middleware integration

3. **User Domain Model**
   - Rich domain model with business logic
   - Value objects and invariants
   - Domain event system

4. **User Service Layer**
   - Application service orchestration
   - Business workflow management
   - Dependency injection

5. **Repository Pattern**
   - Interface-based abstraction
   - PostgreSQL and In-Memory implementations
   - Query building and data mapping

6. **Authentication System**
   - JWT token management
   - Role-based access control
   - Permission-based authorization

7. **API Controllers**
   - REST API endpoints
   - Request validation
   - Error handling

8. **Middleware Stack**
   - Authentication middleware
   - Rate limiting
   - Security headers

9. **Logging System**
   - Structured logging with Winston
   - Request/response logging
   - Error logging

10. **External Services**
    - Email service with multiple providers
    - Audit logging service
    - Hashing service with bcrypt

### 🔄 Integration Points

- **TDD Framework**: Integrated with existing test structure
- **Mock Factories**: Compatible with existing mock patterns
- **Builder Pattern**: Extends existing UserBuilder
- **Configuration**: Environment-safe with validation
- **Logging**: Structured logging throughout

## 🎯 Key Benefits

1. **Testability**: Full mock-driven testing with London School TDD
2. **Maintainability**: Clear separation of concerns with hexagonal architecture
3. **Scalability**: Interface-based design for easy extension
4. **Security**: Built-in security features and validation
5. **Monitoring**: Comprehensive logging and audit trails
6. **Configuration**: Environment-safe configuration management
7. **Error Handling**: Structured error handling throughout
8. **Documentation**: Self-documenting code with clear interfaces

This implementation provides a solid foundation for building scalable, maintainable applications following SPARC methodology and modern software engineering practices.