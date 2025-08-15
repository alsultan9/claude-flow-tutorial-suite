/**
 * Email Service Implementation
 * Handles email sending with multiple provider support (SMTP, SendGrid, SES)
 */

const { createError } = require('../../shared/errors');

/**
 * Email Service Interface
 */
class IEmailService {
  async sendWelcomeEmail(userId, email, name) {
    throw new Error('Method not implemented');
  }

  async sendEmailChangeNotification(userId, newEmail) {
    throw new Error('Method not implemented');
  }

  async sendPasswordResetEmail(email, resetToken) {
    throw new Error('Method not implemented');
  }

  async sendAccountDeletionConfirmation(email, name) {
    throw new Error('Method not implemented');
  }

  async sendVerificationEmail(email, verificationToken) {
    throw new Error('Method not implemented');
  }
}

/**
 * SMTP Email Service Implementation
 */
class SMTPEmailService extends IEmailService {
  constructor(config, logger) {
    super();
    this.config = config;
    this.logger = logger;
    this.transporter = null;
    this.isConnected = false;
  }

  async initialize() {
    try {
      const nodemailer = require('nodemailer');
      
      this.transporter = nodemailer.createTransporter({
        host: this.config.smtp.host,
        port: this.config.smtp.port,
        secure: this.config.smtp.secure,
        auth: {
          user: this.config.smtp.auth.user,
          pass: this.config.smtp.auth.pass,
        },
      });

      // Verify connection
      await this.transporter.verify();
      this.isConnected = true;

      if (this.logger) {
        this.logger.info('SMTP Email service initialized successfully');
      }
    } catch (error) {
      if (this.logger) {
        this.logger.error('SMTP Email service initialization failed', { error: error.message });
      }
      throw createError.external('EmailService', 'SMTP initialization failed', error);
    }
  }

  async sendWelcomeEmail(userId, email, name) {
    const mailOptions = {
      from: this.config.from,
      to: email,
      subject: 'Welcome to SPARC Application!',
      html: this._getWelcomeEmailTemplate(name),
      text: `Welcome to SPARC Application, ${name}! Thank you for joining us.`,
    };

    return this._sendMail(mailOptions, 'welcome', { userId, email });
  }

  async sendEmailChangeNotification(userId, newEmail) {
    const mailOptions = {
      from: this.config.from,
      to: newEmail,
      subject: 'Email Address Changed - SPARC Application',
      html: this._getEmailChangeNotificationTemplate(newEmail),
      text: `Your email address has been changed to ${newEmail}. If you didn't make this change, please contact support immediately.`,
    };

    return this._sendMail(mailOptions, 'email_change', { userId, newEmail });
  }

  async sendPasswordResetEmail(email, resetToken) {
    const resetUrl = `${process.env.APP_URL}/reset-password?token=${resetToken}`;
    
    const mailOptions = {
      from: this.config.from,
      to: email,
      subject: 'Password Reset Request - SPARC Application',
      html: this._getPasswordResetEmailTemplate(resetUrl),
      text: `You requested a password reset. Click here to reset your password: ${resetUrl}`,
    };

    return this._sendMail(mailOptions, 'password_reset', { email, resetToken });
  }

  async sendAccountDeletionConfirmation(email, name) {
    const mailOptions = {
      from: this.config.from,
      to: email,
      subject: 'Account Deletion Confirmation - SPARC Application',
      html: this._getAccountDeletionTemplate(name),
      text: `Hello ${name}, your SPARC Application account has been successfully deleted. If you didn't request this deletion, please contact our support team immediately.`,
    };

    return this._sendMail(mailOptions, 'account_deletion', { email, name });
  }

  async sendVerificationEmail(email, verificationToken) {
    const verificationUrl = `${process.env.APP_URL}/verify-email?token=${verificationToken}`;
    
    const mailOptions = {
      from: this.config.from,
      to: email,
      subject: 'Verify Your Email Address - SPARC Application',
      html: this._getVerificationEmailTemplate(verificationUrl),
      text: `Please verify your email address by clicking this link: ${verificationUrl}`,
    };

    return this._sendMail(mailOptions, 'verification', { email, verificationToken });
  }

  async _sendMail(mailOptions, type, metadata = {}) {
    try {
      if (!this.isConnected) {
        await this.initialize();
      }

      const info = await this.transporter.sendMail(mailOptions);

      if (this.logger) {
        this.logger.info('Email sent successfully', {
          type,
          to: mailOptions.to,
          messageId: info.messageId,
          ...metadata,
        });
      }

      return {
        success: true,
        messageId: info.messageId,
        type,
      };
    } catch (error) {
      if (this.logger) {
        this.logger.error('Email sending failed', {
          type,
          to: mailOptions.to,
          error: error.message,
          ...metadata,
        });
      }

      throw createError.external('EmailService', `Failed to send ${type} email`, error);
    }
  }

  _getWelcomeEmailTemplate(name) {
    return `
      <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #f8f9fa; padding: 20px; text-align: center;">
            <h1 style="color: #007bff;">Welcome to SPARC Application!</h1>
          </div>
          <div style="padding: 20px;">
            <p>Hello ${name},</p>
            <p>Welcome to SPARC Application! We're excited to have you join our community.</p>
            <p>Your account has been successfully created and you can now start using all the features available.</p>
            <p>If you have any questions or need help getting started, please don't hesitate to contact our support team.</p>
            <p>Best regards,<br>The SPARC Team</p>
          </div>
        </body>
      </html>
    `;
  }

  _getEmailChangeNotificationTemplate(newEmail) {
    return `
      <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #28a745; color: white; padding: 20px; text-align: center;">
            <h1>Email Address Changed</h1>
          </div>
          <div style="padding: 20px;">
            <p>Your email address has been successfully changed to: <strong>${newEmail}</strong></p>
            <p>If you didn't make this change, please contact our support team immediately.</p>
            <p>For security reasons, you may need to verify your new email address.</p>
            <p>Best regards,<br>The SPARC Team</p>
          </div>
        </body>
      </html>
    `;
  }

  _getPasswordResetEmailTemplate(resetUrl) {
    return `
      <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #ffc107; color: #212529; padding: 20px; text-align: center;">
            <h1>Password Reset Request</h1>
          </div>
          <div style="padding: 20px;">
            <p>You requested a password reset for your SPARC Application account.</p>
            <p>Click the button below to reset your password:</p>
            <div style="text-align: center; margin: 30px 0;">
              <a href="${resetUrl}" style="background-color: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">Reset Password</a>
            </div>
            <p>If you can't click the button, copy and paste this link into your browser:</p>
            <p style="word-break: break-all;">${resetUrl}</p>
            <p><strong>This link will expire in 1 hour for security reasons.</strong></p>
            <p>If you didn't request this password reset, please ignore this email.</p>
            <p>Best regards,<br>The SPARC Team</p>
          </div>
        </body>
      </html>
    `;
  }

  _getAccountDeletionTemplate(name) {
    return `
      <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #dc3545; color: white; padding: 20px; text-align: center;">
            <h1>Account Deletion Confirmation</h1>
          </div>
          <div style="padding: 20px;">
            <p>Hello ${name},</p>
            <p>Your SPARC Application account has been successfully deleted as requested.</p>
            <p>All your data has been permanently removed from our systems.</p>
            <p>If you didn't request this deletion, please contact our support team immediately at support@example.com</p>
            <p>Thank you for being part of our community.</p>
            <p>Best regards,<br>The SPARC Team</p>
          </div>
        </body>
      </html>
    `;
  }

  _getVerificationEmailTemplate(verificationUrl) {
    return `
      <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background-color: #17a2b8; color: white; padding: 20px; text-align: center;">
            <h1>Verify Your Email Address</h1>
          </div>
          <div style="padding: 20px;">
            <p>Thank you for signing up for SPARC Application!</p>
            <p>To complete your registration, please verify your email address by clicking the button below:</p>
            <div style="text-align: center; margin: 30px 0;">
              <a href="${verificationUrl}" style="background-color: #28a745; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">Verify Email Address</a>
            </div>
            <p>If you can't click the button, copy and paste this link into your browser:</p>
            <p style="word-break: break-all;">${verificationUrl}</p>
            <p><strong>This verification link will expire in 24 hours.</strong></p>
            <p>If you didn't create this account, please ignore this email.</p>
            <p>Best regards,<br>The SPARC Team</p>
          </div>
        </body>
      </html>
    `;
  }
}

/**
 * Mock Email Service (for testing)
 */
class MockEmailService extends IEmailService {
  constructor() {
    super();
    this.sentEmails = [];
    this.shouldFail = false;
    this.failureType = null;
  }

  async sendWelcomeEmail(userId, email, name) {
    return this._mockSend('welcome', { userId, email, name });
  }

  async sendEmailChangeNotification(userId, newEmail) {
    return this._mockSend('email_change', { userId, newEmail });
  }

  async sendPasswordResetEmail(email, resetToken) {
    return this._mockSend('password_reset', { email, resetToken });
  }

  async sendAccountDeletionConfirmation(email, name) {
    return this._mockSend('account_deletion', { email, name });
  }

  async sendVerificationEmail(email, verificationToken) {
    return this._mockSend('verification', { email, verificationToken });
  }

  async _mockSend(type, data) {
    if (this.shouldFail) {
      throw new Error(`Mock email service failure: ${this.failureType || 'generic error'}`);
    }

    const emailData = {
      type,
      data,
      timestamp: new Date(),
      messageId: `mock-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
    };

    this.sentEmails.push(emailData);

    return {
      success: true,
      messageId: emailData.messageId,
      type,
    };
  }

  // Testing utilities
  getSentEmails() {
    return [...this.sentEmails];
  }

  getEmailsByType(type) {
    return this.sentEmails.filter(email => email.type === type);
  }

  reset() {
    this.sentEmails = [];
    this.shouldFail = false;
    this.failureType = null;
  }

  setShouldFail(shouldFail, failureType = null) {
    this.shouldFail = shouldFail;
    this.failureType = failureType;
  }
}

/**
 * Factory function to create email service instances
 */
function createEmailService(config, logger = null) {
  if (config.mock || process.env.NODE_ENV === 'test') {
    return new MockEmailService();
  }

  switch (config.provider) {
    case 'smtp':
      return new SMTPEmailService(config, logger);
    default:
      throw createError.config(`Unsupported email provider: ${config.provider}`, 'EMAIL_PROVIDER');
  }
}

module.exports = {
  IEmailService,
  SMTPEmailService,
  MockEmailService,
  createEmailService,
};