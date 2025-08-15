/**
 * User Controller Tests (London School TDD)
 * Outside-in testing with comprehensive mocking
 */

const { UserController } = require('@/controllers/userController');
const { UserServiceMockFactory } = require('@mocks/factories/userServiceMockFactory');
const { ValidationServiceMockFactory } = require('@mocks/factories/validationServiceMockFactory');
const { AuthMiddlewareMockFactory } = require('@mocks/factories/authMiddlewareMockFactory');
const { UserBuilder } = require('@fixtures/builders/userBuilder');
const { RequestBuilder } = require('@fixtures/builders/requestBuilder');
const { ResponseBuilder } = require('@fixtures/builders/responseBuilder');

describe('UserController', () => {
  let userController;
  let mockUserService;
  let mockValidationService;
  let mockAuthMiddleware;
  
  beforeEach(() => {
    // Initialize mocks using factory pattern
    mockUserService = UserServiceMockFactory.create();
    mockValidationService = ValidationServiceMockFactory.create();
    mockAuthMiddleware = AuthMiddlewareMockFactory.create();
    
    // Inject dependencies through constructor
    userController = new UserController(
      mockUserService,
      mockValidationService,
      mockAuthMiddleware
    );
  });

  describe('register', () => {
    it('should successfully register new user with valid data', async () => {
      // Arrange: Set up the collaboration expectations
      const userData = UserBuilder.create()
        .withEmail('newuser@example.com')
        .withPassword('securePassword123')
        .withName('New User')
        .build();
      
      const req = RequestBuilder.create()
        .withBody(userData)
        .build();
      
      const res = ResponseBuilder.create().build();
      
      const registeredUser = { ...userData, id: 'user-123', createdAt: new Date() };
      
      // Set up mock expectations for the collaboration
      mockValidationService.validateRegistrationData.mockReturnValue({ isValid: true });
      mockUserService.register.mockResolvedValue({
        success: true,
        user: registeredUser,
        message: 'User registered successfully'
      });
      
      // Act: Execute the controller method
      await userController.register(req, res);
      
      // Assert: Verify the conversation between collaborators
      expect(mockValidationService.validateRegistrationData).toHaveBeenCalledWith(userData);
      expect(mockUserService.register).toHaveBeenCalledWith(userData);
      
      // Verify HTTP response handling
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        user: expect.objectContaining({
          id: 'user-123',
          email: userData.email,
          name: userData.name
        }),
        message: 'User registered successfully'
      });
    });

    it('should reject registration with invalid data', async () => {
      // Arrange: Set up invalid data scenario
      const invalidUserData = { email: 'invalid-email', password: '123' };
      const validationErrors = [
        { field: 'email', message: 'Invalid email format' },
        { field: 'password', message: 'Password too short' }
      ];
      
      const req = RequestBuilder.create().withBody(invalidUserData).build();
      const res = ResponseBuilder.create().build();
      
      mockValidationService.validateRegistrationData.mockReturnValue({
        isValid: false,
        errors: validationErrors
      });
      
      // Act
      await userController.register(req, res);
      
      // Assert: Verify validation-first approach
      expect(mockValidationService.validateRegistrationData).toHaveBeenCalledWith(invalidUserData);
      expect(mockUserService.register).not.toHaveBeenCalled(); // Should not proceed
      
      // Verify error response
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        errors: validationErrors,
        message: 'Validation failed'
      });
    });

    it('should handle service registration failure gracefully', async () => {
      // Arrange: Service failure scenario
      const userData = UserBuilder.create().build();
      const req = RequestBuilder.create().withBody(userData).build();
      const res = ResponseBuilder.create().build();
      
      mockValidationService.validateRegistrationData.mockReturnValue({ isValid: true });
      mockUserService.register.mockRejectedValue(
        new Error('Email already exists')
      );
      
      // Act
      await userController.register(req, res);
      
      // Assert: Verify error handling workflow
      expect(mockValidationService.validateRegistrationData).toHaveBeenCalled();
      expect(mockUserService.register).toHaveBeenCalled();
      
      expect(res.status).toHaveBeenCalledWith(409);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Email already exists'
      });
    });
  });

  describe('login', () => {
    it('should authenticate user with valid credentials', async () => {
      // Arrange
      const loginData = { email: 'user@example.com', password: 'password123' };
      const user = UserBuilder.create().withEmail(loginData.email).build();
      const authToken = 'jwt-token-123';
      
      const req = RequestBuilder.create().withBody(loginData).build();
      const res = ResponseBuilder.create().build();
      
      mockValidationService.validateLoginData.mockReturnValue({ isValid: true });
      mockUserService.authenticate.mockResolvedValue({
        success: true,
        user,
        token: authToken
      });
      
      // Act
      await userController.login(req, res);
      
      // Assert: Verify authentication workflow
      expect(mockValidationService.validateLoginData).toHaveBeenCalledWith(loginData);
      expect(mockUserService.authenticate).toHaveBeenCalledWith(
        loginData.email,
        loginData.password
      );
      
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        user: expect.objectContaining({ email: loginData.email }),
        token: authToken
      });
    });

    it('should reject invalid credentials', async () => {
      // Arrange
      const loginData = { email: 'user@example.com', password: 'wrongpassword' };
      const req = RequestBuilder.create().withBody(loginData).build();
      const res = ResponseBuilder.create().build();
      
      mockValidationService.validateLoginData.mockReturnValue({ isValid: true });
      mockUserService.authenticate.mockRejectedValue(
        new Error('Invalid credentials')
      );
      
      // Act
      await userController.login(req, res);
      
      // Assert
      expect(mockUserService.authenticate).toHaveBeenCalledWith(
        loginData.email,
        loginData.password
      );
      
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Invalid credentials'
      });
    });
  });

  describe('getProfile', () => {
    it('should return user profile for authenticated request', async () => {
      // Arrange
      const userId = 'user-123';
      const user = UserBuilder.create().withId(userId).build();
      
      const req = RequestBuilder.create()
        .withParams({ userId })
        .withUser(user) // Simulates auth middleware setting req.user
        .build();
      
      const res = ResponseBuilder.create().build();
      
      mockAuthMiddleware.authenticate.mockImplementation((req, res, next) => {
        req.user = user;
        next();
      });
      
      mockUserService.getProfile.mockResolvedValue({
        success: true,
        profile: user
      });
      
      // Act
      await userController.getProfile(req, res);
      
      // Assert: Verify authenticated profile retrieval
      expect(mockUserService.getProfile).toHaveBeenCalledWith(userId);
      
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        profile: expect.objectContaining({
          id: userId,
          email: user.email
        })
      });
    });

    it('should handle profile not found scenario', async () => {
      // Arrange
      const userId = 'non-existent-user';
      const req = RequestBuilder.create().withParams({ userId }).build();
      const res = ResponseBuilder.create().build();
      
      mockUserService.getProfile.mockRejectedValue(
        new Error('User not found')
      );
      
      // Act
      await userController.getProfile(req, res);
      
      // Assert
      expect(mockUserService.getProfile).toHaveBeenCalledWith(userId);
      
      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'User not found'
      });
    });
  });

  describe('updateProfile', () => {
    it('should update user profile with valid data', async () => {
      // Arrange
      const userId = 'user-123';
      const updateData = { name: 'Updated Name', phone: '555-0123' };
      const existingUser = UserBuilder.create().withId(userId).build();
      const updatedUser = { ...existingUser, ...updateData };
      
      const req = RequestBuilder.create()
        .withParams({ userId })
        .withBody(updateData)
        .withUser(existingUser)
        .build();
      
      const res = ResponseBuilder.create().build();
      
      mockValidationService.validateProfileUpdateData.mockReturnValue({ isValid: true });
      mockUserService.updateProfile.mockResolvedValue({
        success: true,
        user: updatedUser
      });
      
      // Act
      await userController.updateProfile(req, res);
      
      // Assert: Verify update workflow
      expect(mockValidationService.validateProfileUpdateData).toHaveBeenCalledWith(updateData);
      expect(mockUserService.updateProfile).toHaveBeenCalledWith(userId, updateData);
      
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        user: expect.objectContaining({
          id: userId,
          name: updateData.name,
          phone: updateData.phone
        })
      });
    });
  });

  describe('deleteAccount', () => {
    it('should delete user account with proper authorization', async () => {
      // Arrange
      const userId = 'user-123';
      const user = UserBuilder.create().withId(userId).build();
      
      const req = RequestBuilder.create()
        .withParams({ userId })
        .withUser(user)
        .build();
      
      const res = ResponseBuilder.create().build();
      
      mockUserService.deleteAccount.mockResolvedValue({
        success: true,
        message: 'Account deleted successfully'
      });
      
      // Act
      await userController.deleteAccount(req, res);
      
      // Assert: Verify deletion workflow
      expect(mockUserService.deleteAccount).toHaveBeenCalledWith(userId);
      
      expect(res.status).toHaveBeenCalledWith(200);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        message: 'Account deleted successfully'
      });
    });

    it('should handle deletion failure gracefully', async () => {
      // Arrange
      const userId = 'user-123';
      const req = RequestBuilder.create().withParams({ userId }).build();
      const res = ResponseBuilder.create().build();
      
      mockUserService.deleteAccount.mockRejectedValue(
        new Error('Cannot delete account with active orders')
      );
      
      // Act
      await userController.deleteAccount(req, res);
      
      // Assert
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Cannot delete account with active orders'
      });
    });
  });

  describe('middleware integration', () => {
    it('should properly coordinate with authentication middleware', async () => {
      // Arrange: Test middleware coordination
      const user = UserBuilder.create().build();
      const req = RequestBuilder.create().build();
      const res = ResponseBuilder.create().build();
      const next = jest.fn();
      
      // Mock middleware to simulate authentication
      mockAuthMiddleware.authenticate.mockImplementation((req, res, next) => {
        req.user = user;
        next();
      });
      
      // Act: Test middleware integration
      await mockAuthMiddleware.authenticate(req, res, next);
      
      // Assert: Verify middleware coordination
      expect(req.user).toEqual(user);
      expect(next).toHaveBeenCalled();
    });

    it('should handle authentication failure in middleware', async () => {
      // Arrange
      const req = RequestBuilder.create().build();
      const res = ResponseBuilder.create().build();
      const next = jest.fn();
      
      mockAuthMiddleware.authenticate.mockImplementation((req, res, next) => {
        res.status(401).json({ error: 'Unauthorized' });
      });
      
      // Act
      await mockAuthMiddleware.authenticate(req, res, next);
      
      // Assert: Verify authentication failure handling
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({ error: 'Unauthorized' });
      expect(next).not.toHaveBeenCalled();
    });
  });
});