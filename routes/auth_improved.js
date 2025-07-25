const express = require('express');
const { body, validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const { generateToken } = require('../middleware/auth');
const bitnobService = require('../services/bitnobService');
// Add database import when implemented
// const User = require('../models/User');

const router = express.Router();

// Validation middleware
const validateRegistration = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Password must contain uppercase, lowercase, number, and special character'),
  body('firstName').trim().isLength({ min: 1, max: 50 }).withMessage('First name required (1-50 characters)'),
  body('lastName').trim().isLength({ min: 1, max: 50 }).withMessage('Last name required (1-50 characters)'),
  body('phone').isMobilePhone().withMessage('Valid phone number required'),
  body('countryCode').optional().isLength({ min: 2, max: 3 }).withMessage('Valid country code required')
];

const validateLogin = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').notEmpty().withMessage('Password required')
];

const validatePasswordReset = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email required')
];

const validatePasswordChange = [
  body('currentPassword').notEmpty().withMessage('Current password required'),
  body('newPassword')
    .isLength({ min: 8 })
    .withMessage('New password must be at least 8 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('New password must contain uppercase, lowercase, number, and special character')
];

// Helper function to handle validation errors
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      error: 'Validation failed',
      details: errors.array()
    });
  }
  next();
};

// POST /api/auth/signup
router.post('/signup', validateRegistration, handleValidationErrors, async (req, res, next) => {
  try {
    const { email, password, firstName, lastName, phone, countryCode } = req.body;

    console.log(`🔐 Registration attempt for email: ${email}`);

    // TODO: Check if user already exists in database
    // const existingUser = await User.findOne({ where: { email } });
    // if (existingUser) {
    //   return res.status(409).json({
    //     success: false,
    //     error: 'User already exists with this email'
    //   });
    // }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, parseInt(process.env.BCRYPT_ROUNDS) || 12);

    // Create customer in Bitnob first
    let bitnobCustomer = null;
    try {
      const bitnobCustomerData = {
        email,
        firstName,
        lastName,
        phone,
        countryCode: countryCode || '+234' // Default to Nigeria
      };

      bitnobCustomer = await bitnobService.createCustomer(bitnobCustomerData);
      console.log(`✅ Bitnob customer created:`, bitnobCustomer.data);
    } catch (bitnobError) {
      console.warn(`⚠️ Failed to create Bitnob customer:`, bitnobError.message);
      // Don't fail registration if Bitnob customer creation fails
      // User can complete KYC later
    }

    // Create local user record
    const userData = {
      email,
      password: hashedPassword,
      firstName,
      lastName,
      phone,
      bitnobCustomerId: bitnobCustomer?.data?.id,
      emailVerified: false, // Require email verification
      kycStatus: 'pending'
    };

    // TODO: Save to database
    // const newUser = await User.create(userData);
    
    // For now, simulate user creation
    const newUser = {
      id: `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      ...userData,
      createdAt: new Date().toISOString()
    };

    // Generate JWT token
    const token = generateToken({
      userId: newUser.id,
      email: newUser.email,
      firstName: newUser.firstName,
      lastName: newUser.lastName,
      emailVerified: newUser.emailVerified
    });

    console.log(`✅ Registration successful for: ${email}`);

    // TODO: Send email verification
    // await sendVerificationEmail(email, newUser.id);

    res.status(201).json({
      success: true,
      message: 'User registered successfully. Please verify your email.',
      data: {
        user: {
          id: newUser.id,
          email: newUser.email,
          firstName: newUser.firstName,
          lastName: newUser.lastName,
          phone: newUser.phone,
          emailVerified: newUser.emailVerified,
          kycStatus: newUser.kycStatus,
          createdAt: newUser.createdAt
        },
        token: token,
        requiresEmailVerification: true
      }
    });

  } catch (error) {
    console.error('❌ Registration error:', error.message);
    next(error);
  }
});

// POST /api/auth/signin
router.post('/signin', validateLogin, handleValidationErrors, async (req, res, next) => {
  try {
    const { email, password } = req.body;

    console.log(`🔐 Login attempt for email: ${email}`);

    // TODO: Find user in database
    // const user = await User.findOne({ where: { email } });
    // if (!user) {
    //   return res.status(401).json({
    //     success: false,
    //     error: 'Invalid email or password'
    //   });
    // }

    // For demo purposes - simulate user lookup
    const demoUser = {
      id: `user_demo_${Date.now()}`,
      email: email,
      firstName: 'Demo',
      lastName: 'User',
      phone: '+1234567890',
      password: await bcrypt.hash('password123', 12), // Demo password
      emailVerified: true,
      kycStatus: 'approved',
      bitnobCustomerId: 'demo_customer_id',
      createdAt: new Date().toISOString()
    };

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, demoUser.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        error: 'Invalid email or password'
      });
    }

    // Check if account is active/not suspended
    // if (user.status === 'suspended') {
    //   return res.status(403).json({
    //     success: false,
    //     error: 'Account suspended. Please contact support.'
    //   });
    // }

    // Generate JWT token
    const token = generateToken({
      userId: demoUser.id,
      email: demoUser.email,
      firstName: demoUser.firstName,
      lastName: demoUser.lastName,
      emailVerified: demoUser.emailVerified
    });

    // TODO: Update last login timestamp
    // await User.update({ lastLoginAt: new Date() }, { where: { id: user.id } });

    console.log(`✅ Login successful for: ${email}`);

    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          id: demoUser.id,
          email: demoUser.email,
          firstName: demoUser.firstName,
          lastName: demoUser.lastName,
          phone: demoUser.phone,
          emailVerified: demoUser.emailVerified,
          kycStatus: demoUser.kycStatus,
          createdAt: demoUser.createdAt
        },
        token: token
      }
    });

  } catch (error) {
    console.error('❌ Login error:', error.message);
    next(error);
  }
});

// POST /api/auth/forgot-password
router.post('/forgot-password', validatePasswordReset, handleValidationErrors, async (req, res, next) => {
  try {
    const { email } = req.body;

    console.log(`🔑 Password reset request for: ${email}`);

    // TODO: Find user and generate reset token
    // const user = await User.findOne({ where: { email } });
    // if (!user) {
    //   // Don't reveal if email exists for security
    //   return res.status(200).json({
    //     success: true,
    //     message: 'If an account with that email exists, we have sent a password reset link.'
    //   });
    // }

    // TODO: Generate reset token and send email
    // const resetToken = crypto.randomBytes(32).toString('hex');
    // await User.update({ 
    //   passwordResetToken: resetToken,
    //   passwordResetExpires: new Date(Date.now() + 3600000) // 1 hour
    // }, { where: { id: user.id } });

    // await sendPasswordResetEmail(email, resetToken);

    res.status(200).json({
      success: true,
      message: 'If an account with that email exists, we have sent a password reset link.'
    });

  } catch (error) {
    console.error('❌ Password reset error:', error.message);
    next(error);
  }
});

// POST /api/auth/change-password
router.post('/change-password', 
  require('../middleware/auth').authenticateToken,
  validatePasswordChange, 
  handleValidationErrors, 
  async (req, res, next) => {
    try {
      const { currentPassword, newPassword } = req.body;
      const userId = req.user.userId;

      console.log(`🔑 Password change request for user: ${userId}`);

      // TODO: Get user from database
      // const user = await User.findByPk(userId);
      // if (!user) {
      //   return res.status(404).json({
      //     success: false,
      //     error: 'User not found'
      //   });
      // }

      // For demo - simulate getting user
      const user = { password: await bcrypt.hash('oldpassword', 12) };

      // Verify current password
      const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.password);
      if (!isCurrentPasswordValid) {
        return res.status(400).json({
          success: false,
          error: 'Current password is incorrect'
        });
      }

      // Hash new password
      const hashedNewPassword = await bcrypt.hash(newPassword, parseInt(process.env.BCRYPT_ROUNDS) || 12);

      // TODO: Update password in database
      // await User.update({ password: hashedNewPassword }, { where: { id: userId } });

      console.log(`✅ Password changed successfully for user: ${userId}`);

      res.status(200).json({
        success: true,
        message: 'Password changed successfully'
      });

    } catch (error) {
      console.error('❌ Password change error:', error.message);
      next(error);
    }
  }
);

// POST /api/auth/verify-email
router.post('/verify-email', async (req, res, next) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({
        success: false,
        error: 'Verification token is required'
      });
    }

    // TODO: Verify email token
    // const user = await User.findOne({ where: { emailVerificationToken: token } });
    // if (!user) {
    //   return res.status(400).json({
    //     success: false,
    //     error: 'Invalid or expired verification token'
    //   });
    // }

    // await User.update({ 
    //   emailVerified: true,
    //   emailVerificationToken: null
    // }, { where: { id: user.id } });

    console.log(`✅ Email verified for token: ${token}`);

    res.status(200).json({
      success: true,
      message: 'Email verified successfully'
    });

  } catch (error) {
    console.error('❌ Email verification error:', error.message);
    next(error);
  }
});

// POST /api/auth/logout
router.post('/logout', (req, res) => {
  // Since we're using stateless JWT, logout is handled client-side
  // The client should remove the token from storage
  console.log('🚪 User logout');
  
  res.status(200).json({
    success: true,
    message: 'Logout successful'
  });
});

// POST /api/auth/request-2fa - Request OTP for 2FA
router.post('/request-2fa', require('../middleware/auth').authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.userId;
    
    console.log(`🔐 2FA OTP request for user: ${userId}`);
    
    // TODO: Generate and send OTP via SMS/Email
    // For demo purposes, we'll simulate success
    const otp = Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit OTP
    
    // In production, you would:
    // 1. Store OTP in Redis/database with expiration
    // 2. Send via SMS/Email service
    // await sendSMS(user.phone, `Your Pesagram OTP: ${otp}`);
    
    console.log(`📱 Demo OTP generated: ${otp} (for user: ${userId})`);
    
    res.status(200).json({
      success: true,
      message: 'OTP sent successfully',
      // Remove this in production - only for demo
      debug_otp: process.env.NODE_ENV === 'development' ? otp : undefined
    });

  } catch (error) {
    console.error('❌ 2FA OTP request error:', error.message);
    next(error);
  }
});

// POST /api/auth/verify-2fa - Verify OTP for 2FA
router.post('/verify-2fa', require('../middleware/auth').authenticateToken, [
  body('otp').isLength({ min: 6, max: 6 }).withMessage('OTP must be 6 digits')
], handleValidationErrors, async (req, res, next) => {
  try {
    const { otp } = req.body;
    const userId = req.user.userId;
    
    console.log(`🔐 2FA OTP verification for user: ${userId}, OTP: ${otp}`);
    
    // TODO: Verify OTP from Redis/database
    // For demo purposes, accept any 6-digit OTP
    if (otp.length === 6 && /^\d{6}$/.test(otp)) {
      res.status(200).json({
        success: true,
        message: 'OTP verified successfully'
      });
    } else {
      res.status(400).json({
        success: false,
        error: 'Invalid OTP'
      });
    }

  } catch (error) {
    console.error('❌ 2FA OTP verification error:', error.message);
    next(error);
  }
});

// GET /api/auth/verify - Verify JWT token
router.get('/verify', require('../middleware/auth').authenticateToken, (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Token is valid',
    data: {
      user: req.user
    }
  });
});

module.exports = router;
