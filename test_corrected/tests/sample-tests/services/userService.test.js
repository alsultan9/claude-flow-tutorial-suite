/**
 * User Service Tests (London School TDD)
 * Mock-driven service layer testing with behavior verification
 */

const { UserService } = require('@/services/userService');
const { UserRepositoryMockFactory } = require('@mocks/factories/userRepositoryMockFactory');
const { EmailServiceMockFactory } = require('@mocks/factories/emailServiceMockFactory');
const { HashingServiceMockFactory } = require('@mocks/factories/hashingServiceMockFactory');
const { AuditLogMockFactory } = require('@mocks/factories/auditLogMockFactory');
const { UserBuilder } = require('@fixtures/builders/userBuilder');

describe('UserService', () => {
  let userService;
  let mockUserRepository;
  let mockEmailService;
  let mockHashingService;
  let mockAuditLog;

  beforeEach(() => {
    // Initialize all mock dependencies
    mockUserRepository = UserRepositoryMockFactory.create();
    mockEmailService = EmailServiceMockFactory.create();
    mockHashingService = HashingServiceMockFactory.create();
    mockAuditLog = AuditLogMockFactory.create();

    // Inject mocks into service
    userService = new UserService(
      mockUserRepository,
      mockEmailService,
      mockHashingService,
      mockAuditLog
    );
  });

  describe('register', () => {
    it('should orchestrate complete user registration workflow', async () => {
      // Arrange: Set up the collaboration scenario
      const userData = UserBuilder.create()
        .withEmail('newuser@example.com')
        .withPassword('plainPassword123')
        .withName('New User')
        .build();

      const hashedPassword = 'hashed_password_123';
      const savedUser = {
        ...userData,
        id: 'user-456',
        password: hashedPassword,
        createdAt: new Date()
      };

      // Define mock expectations for the workflow
      mockUserRepository.findByEmail.mockResolvedValue(null); // User doesn't exist
      mockHashingService.hash.mockResolvedValue(hashedPassword);
      mockUserRepository.save.mockResolvedValue(savedUser);
      mockEmailService.sendWelcomeEmail.mockResolvedValue(true);
      mockAuditLog.logUserRegistration.mockResolvedValue(true);

      // Act: Execute the registration workflow
      const result = await userService.register(userData);

      // Assert: Verify the complete conversation flow
      expect(mockUserRepository.findByEmail).toHaveBeenCalledWith(userData.email);
      expect(mockHashingService.hash).toHaveBeenCalledWith(userData.password);
      expect(mockUserRepository.save).toHaveBeenCalledWith({
        ...userData,
        password: hashedPassword
      });
      expect(mockEmailService.sendWelcomeEmail).toHaveBeenCalledWith(
        savedUser.id,
        savedUser.email,
        savedUser.name
      );
      expect(mockAuditLog.logUserRegistration).toHaveBeenCalledWith(savedUser.id);

      // Verify result structure
      expect(result).toEqual({
        success: true,
        user: expect.objectContaining({
          id: savedUser.id,
          email: savedUser.email,
          name: savedUser.name
        }),
        message: 'User registered successfully'
      });

      // Verify password is not exposed in result
      expect(result.user.password).toBeUndefined();
    });

    it('should reject registration when email already exists', async () => {
      // Arrange: Existing user scenario
      const userData = UserBuilder.create().build();
      const existingUser = UserBuilder.create()
        .withEmail(userData.email)
        .withId('existing-123')
        .build();

      mockUserRepository.findByEmail.mockResolvedValue(existingUser);

      // Act & Assert: Verify early termination on duplicate email
      await expect(userService.register(userData)).rejects.toThrow('Email already exists');

      // Verify workflow stops at email check
      expect(mockUserRepository.findByEmail).toHaveBeenCalledWith(userData.email);
      expect(mockHashingService.hash).not.toHaveBeenCalled();
      expect(mockUserRepository.save).not.toHaveBeenCalled();
      expect(mockEmailService.sendWelcomeEmail).not.toHaveBeenCalled();
    });

    it('should handle password hashing failure gracefully', async () => {
      // Arrange: Hashing service failure
      const userData = UserBuilder.create().build();
      const hashingError = new Error('Hashing service unavailable');

      mockUserRepository.findByEmail.mockResolvedValue(null);
      mockHashingService.hash.mockRejectedValue(hashingError);

      // Act & Assert
      await expect(userService.register(userData)).rejects.toThrow('Hashing service unavailable');

      // Verify workflow stops at hashing step
      expect(mockUserRepository.findByEmail).toHaveBeenCalled();
      expect(mockHashingService.hash).toHaveBeenCalled();
      expect(mockUserRepository.save).not.toHaveBeenCalled();
      expect(mockEmailService.sendWelcomeEmail).not.toHaveBeenCalled();
    });

    it('should handle repository save failure with proper cleanup', async () => {
      // Arrange: Repository failure scenario
      const userData = UserBuilder.create().build();
      const hashedPassword = 'hashed_password';
      const saveError = new Error('Database connection failed');

      mockUserRepository.findByEmail.mockResolvedValue(null);
      mockHashingService.hash.mockResolvedValue(hashedPassword);
      mockUserRepository.save.mockRejectedValue(saveError);

      // Act & Assert
      await expect(userService.register(userData)).rejects.toThrow('Database connection failed');

      // Verify attempted save with correct data
      expect(mockUserRepository.save).toHaveBeenCalledWith({
        ...userData,
        password: hashedPassword
      });

      // Verify downstream services not called on save failure
      expect(mockEmailService.sendWelcomeEmail).not.toHaveBeenCalled();
      expect(mockAuditLog.logUserRegistration).not.toHaveBeenCalled();
    });

    it('should continue registration even if welcome email fails', async () => {
      // Arrange: Email service failure scenario
      const userData = UserBuilder.create().build();
      const hashedPassword = 'hashed_password';
      const savedUser = { ...userData, id: 'user-789', password: hashedPassword };

      mockUserRepository.findByEmail.mockResolvedValue(null);
      mockHashingService.hash.mockResolvedValue(hashedPassword);
      mockUserRepository.save.mockResolvedValue(savedUser);
      mockEmailService.sendWelcomeEmail.mockRejectedValue(new Error('Email service down'));
      mockAuditLog.logUserRegistration.mockResolvedValue(true);

      // Act: Should not throw despite email failure
      const result = await userService.register(userData);

      // Assert: Registration still succeeds
      expect(result.success).toBe(true);
      expect(result.user.id).toBe('user-789');

      // Verify all steps were attempted
      expect(mockUserRepository.save).toHaveBeenCalled();
      expect(mockEmailService.sendWelcomeEmail).toHaveBeenCalled();
      expect(mockAuditLog.logUserRegistration).toHaveBeenCalled();
    });
  });

  describe('authenticate', () => {
    it('should successfully authenticate user with valid credentials', async () => {
      // Arrange
      const email = 'user@example.com';
      const plainPassword = 'password123';
      const hashedPassword = 'hashed_password_123';
      
      const storedUser = UserBuilder.create()
        .withEmail(email)
        .withPassword(hashedPassword)
        .build();

      mockUserRepository.findByEmail.mockResolvedValue(storedUser);
      mockHashingService.verify.mockResolvedValue(true);
      mockAuditLog.logUserLogin.mockResolvedValue(true);

      // Act
      const result = await userService.authenticate(email, plainPassword);

      // Assert: Verify authentication workflow
      expect(mockUserRepository.findByEmail).toHaveBeenCalledWith(email);
      expect(mockHashingService.verify).toHaveBeenCalledWith(plainPassword, hashedPassword);
      expect(mockAuditLog.logUserLogin).toHaveBeenCalledWith(storedUser.id, email);

      expect(result).toEqual({
        success: true,
        user: expect.objectContaining({
          id: storedUser.id,
          email: storedUser.email
        }),
        token: expect.any(String)
      });

      // Verify password not exposed
      expect(result.user.password).toBeUndefined();
    });

    it('should reject authentication for non-existent user', async () => {
      // Arrange
      const email = 'nonexistent@example.com';
      const password = 'anypassword';

      mockUserRepository.findByEmail.mockResolvedValue(null);

      // Act & Assert
      await expect(userService.authenticate(email, password)).rejects.toThrow('Invalid credentials');

      // Verify workflow stops at user lookup
      expect(mockUserRepository.findByEmail).toHaveBeenCalledWith(email);
      expect(mockHashingService.verify).not.toHaveBeenCalled();
      expect(mockAuditLog.logUserLogin).not.toHaveBeenCalled();
    });

    it('should reject authentication with invalid password', async () => {
      // Arrange
      const email = 'user@example.com';
      const wrongPassword = 'wrongpassword';
      const storedUser = UserBuilder.create().withEmail(email).build();

      mockUserRepository.findByEmail.mockResolvedValue(storedUser);
      mockHashingService.verify.mockResolvedValue(false);

      // Act & Assert
      await expect(userService.authenticate(email, wrongPassword)).rejects.toThrow('Invalid credentials');

      // Verify password verification was attempted
      expect(mockHashingService.verify).toHaveBeenCalledWith(wrongPassword, storedUser.password);
      expect(mockAuditLog.logUserLogin).not.toHaveBeenCalled();
    });
  });

  describe('getProfile', () => {
    it('should retrieve user profile successfully', async () => {
      // Arrange
      const userId = 'user-123';
      const user = UserBuilder.create().withId(userId).build();

      mockUserRepository.findById.mockResolvedValue(user);

      // Act
      const result = await userService.getProfile(userId);

      // Assert
      expect(mockUserRepository.findById).toHaveBeenCalledWith(userId);
      expect(result).toEqual({
        success: true,
        profile: expect.objectContaining({
          id: userId,
          email: user.email,
          name: user.name
        })
      });

      // Verify sensitive data not exposed
      expect(result.profile.password).toBeUndefined();
    });

    it('should handle profile not found scenario', async () => {
      // Arrange
      const userId = 'non-existent-user';

      mockUserRepository.findById.mockResolvedValue(null);

      // Act & Assert
      await expect(userService.getProfile(userId)).rejects.toThrow('User not found');

      expect(mockUserRepository.findById).toHaveBeenCalledWith(userId);
    });
  });

  describe('updateProfile', () => {
    it('should update user profile with orchestrated workflow', async () => {
      // Arrange
      const userId = 'user-123';
      const updateData = { name: 'Updated Name', phone: '555-0123' };
      const existingUser = UserBuilder.create().withId(userId).build();
      const updatedUser = { ...existingUser, ...updateData, updatedAt: new Date() };

      mockUserRepository.findById.mockResolvedValue(existingUser);
      mockUserRepository.update.mockResolvedValue(updatedUser);
      mockAuditLog.logProfileUpdate.mockResolvedValue(true);

      // Act
      const result = await userService.updateProfile(userId, updateData);

      // Assert: Verify update workflow
      expect(mockUserRepository.findById).toHaveBeenCalledWith(userId);
      expect(mockUserRepository.update).toHaveBeenCalledWith(userId, updateData);
      expect(mockAuditLog.logProfileUpdate).toHaveBeenCalledWith(userId, updateData);

      expect(result).toEqual({
        success: true,
        user: expect.objectContaining({
          id: userId,
          name: updateData.name,
          phone: updateData.phone
        })
      });
    });

    it('should handle email update with duplicate check', async () => {
      // Arrange: Email update scenario
      const userId = 'user-123';
      const updateData = { email: 'newemail@example.com' };
      const existingUser = UserBuilder.create().withId(userId).build();

      mockUserRepository.findById.mockResolvedValue(existingUser);
      mockUserRepository.findByEmail.mockResolvedValue(null); // Email available
      mockUserRepository.update.mockResolvedValue({ ...existingUser, ...updateData });
      mockEmailService.sendEmailChangeNotification.mockResolvedValue(true);
      mockAuditLog.logProfileUpdate.mockResolvedValue(true);

      // Act
      const result = await userService.updateProfile(userId, updateData);

      // Assert: Verify email change workflow
      expect(mockUserRepository.findByEmail).toHaveBeenCalledWith(updateData.email);
      expect(mockEmailService.sendEmailChangeNotification).toHaveBeenCalledWith(
        userId,
        updateData.email
      );

      expect(result.success).toBe(true);
    });
  });

  describe('deleteAccount', () => {
    it('should orchestrate account deletion workflow', async () => {
      // Arrange
      const userId = 'user-123';
      const user = UserBuilder.create().withId(userId).build();

      mockUserRepository.findById.mockResolvedValue(user);
      mockUserRepository.delete.mockResolvedValue(true);
      mockEmailService.sendAccountDeletionConfirmation.mockResolvedValue(true);
      mockAuditLog.logAccountDeletion.mockResolvedValue(true);

      // Act
      const result = await userService.deleteAccount(userId);

      // Assert: Verify deletion workflow
      expect(mockUserRepository.findById).toHaveBeenCalledWith(userId);
      expect(mockUserRepository.delete).toHaveBeenCalledWith(userId);
      expect(mockEmailService.sendAccountDeletionConfirmation).toHaveBeenCalledWith(
        user.email,
        user.name
      );
      expect(mockAuditLog.logAccountDeletion).toHaveBeenCalledWith(userId);

      expect(result).toEqual({
        success: true,
        message: 'Account deleted successfully'
      });
    });

    it('should handle deletion of non-existent user', async () => {
      // Arrange
      const userId = 'non-existent-user';

      mockUserRepository.findById.mockResolvedValue(null);

      // Act & Assert
      await expect(userService.deleteAccount(userId)).rejects.toThrow('User not found');

      // Verify workflow stops at user lookup
      expect(mockUserRepository.findById).toHaveBeenCalledWith(userId);
      expect(mockUserRepository.delete).not.toHaveBeenCalled();
      expect(mockEmailService.sendAccountDeletionConfirmation).not.toHaveBeenCalled();
    });
  });

  describe('interaction order verification', () => {
    it('should maintain proper order in complex workflows', async () => {
      // Arrange: Test interaction sequencing
      const userData = UserBuilder.create().build();
      const hashedPassword = 'hashed_password';
      const savedUser = { ...userData, id: 'user-seq', password: hashedPassword };

      mockUserRepository.findByEmail.mockResolvedValue(null);
      mockHashingService.hash.mockResolvedValue(hashedPassword);
      mockUserRepository.save.mockResolvedValue(savedUser);
      mockEmailService.sendWelcomeEmail.mockResolvedValue(true);
      mockAuditLog.logUserRegistration.mockResolvedValue(true);

      // Act
      await userService.register(userData);

      // Assert: Verify call order using custom matchers
      expect(mockUserRepository.findByEmail).toHaveBeenCalledBefore(mockHashingService.hash);
      expect(mockHashingService.hash).toHaveBeenCalledBefore(mockUserRepository.save);
      expect(mockUserRepository.save).toHaveBeenCalledBefore(mockEmailService.sendWelcomeEmail);
      expect(mockEmailService.sendWelcomeEmail).toHaveBeenCalledBefore(mockAuditLog.logUserRegistration);
    });
  });
});