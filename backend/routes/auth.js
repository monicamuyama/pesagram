const express = require('express');
const { body, validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const { generateToken } = require('../middleware/auth');
const bitnobService = require('../services/bitnobService');
const crypto = require('crypto');

const router = express.Router();

// In-memory store for OTPs (replace with Redis or DB in production)
const otpStore = {};

// Validation middleware
const validateRegistration = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').isLength({ min: 10 }).withMessage('Password must be at least 10 characters'),
  body('firstName').trim().isLength({ min: 1 }).withMessage('First name required'),
  body('lastName').trim().isLength({ min: 1 }).withMessage('Last name required'),
  body('phone').trim().isLength({ min: 10 }).withMessage('Valid phone number required')
];

const validateLogin = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').notEmpty().withMessage('Password required')
];

// Helper function to handle validation errors
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      error: 'Validation failed',
      details: errors.array()
    });
  }
  next();
};

// POST /api/auth/signup
router.post('/signup', validateRegistration, handleValidationErrors, async (req, res, next) => {
  try {
    const { email, password, firstName, lastName, phone } = req.body;

    console.log(`Registration attempt for email: ${email}`);

    // In a real app, you'd store this in a database
    // For demo purposes, we'll simulate user creation
    
    // Hash password for local storage
    const hashedPassword = await bcrypt.hash(password, parseInt(process.env.BCRYPT_ROUNDS) || 12);

    // Create a local user record (in production, save to database)
    const localUser = {
      id: `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      email,
      firstName,
      lastName,
      phone,
      password: hashedPassword,
      createdAt: new Date().toISOString()
    };

    // Create customer record in Bitnob for wallet management
    try {
      const bitnobCustomerData = {
        email,
        firstName,
        lastName,
        phone,
        country: 'NG', // Default to Nigeria
        dateOfBirth: '1990-01-01' // Should be collected from user
      };

      const bitnobResponse = await bitnobService.createUser(bitnobCustomerData);
      console.log(`✅ Bitnob customer created:`, bitnobResponse);
      
      // Store Bitnob customer ID with local user
      localUser.bitnobCustomerId = bitnobResponse.data?.id || bitnobResponse.id;
    } catch (bitnobError) {
      console.warn(`⚠️ Failed to create Bitnob customer:`, bitnobError.message);
      // Continue with local user creation even if Bitnob fails
    }

    // Generate JWT token for our backend
    const token = generateToken({
      userId: localUser.id,
      email: email,
      firstName: firstName,
      lastName: lastName
    });

    console.log(`✅ Registration successful for: ${email}`);

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: {
          id: localUser.id,
          email: localUser.email,
          firstName: localUser.firstName,
          lastName: localUser.lastName,
          phone: localUser.phone,
          isKycVerified: false,
          createdAt: localUser.createdAt
        },
        token: token
      }
    });

  } catch (error) {
    console.error('Registration error:', error.message);
    next(error);
  }
});

// POST /api/auth/signin
router.post('/signin', validateLogin, handleValidationErrors, async (req, res, next) => {
  try {
    const { email, password } = req.body;

    console.log(`Login attempt for email: ${email}`);

    // In a real app, you'd query this from a database
    // For demo purposes, we'll simulate user lookup
    // TODO: Replace with actual database query
    
    // Simulate finding user (in production, query from database)
    // For now, we'll create a demo user for testing
    const demoUser = {
      id: `user_demo_${Date.now()}`,
      email: email,
      firstName: 'Demo',
      lastName: 'User',
      phone: '+1234567890',
      password: await bcrypt.hash('password123456', 12), // Demo password
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

    // Generate JWT token for our backend
    const token = generateToken({
      userId: demoUser.id,
      email: demoUser.email,
      firstName: demoUser.firstName,
      lastName: demoUser.lastName
    });

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
          isKycVerified: false,
          createdAt: demoUser.createdAt
        },
        token: token
      }
    });

  } catch (error) {
    console.error(' Login error:', error.message);
    next(error);
  }
});

// POST /api/auth/logout
router.post('/logout', (req, res) => {
  // Since we're using stateless JWT, logout is handled client-side
  // The client should remove the token from storage
  console.log(' User logout');
  
  res.status(200).json({
    success: true,
    message: 'Logout successful'
  });
});

// POST /api/auth/request-2fa - Request OTP for sensitive action
router.post('/request-2fa', require('../middleware/auth').authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const email = req.user.email;
    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    // Store OTP with expiry (5 min)
    otpStore[userId] = { otp, expires: Date.now() + 5 * 60 * 1000 };
    // TODO: Send OTP via email (stub)
    console.log(`2FA OTP for ${email}: ${otp}`);
    res.status(200).json({ success: true, message: 'OTP sent to your email.' });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to send OTP', details: err.message });
  }
});

// POST /api/auth/verify-2fa - Verify OTP for sensitive action
router.post('/verify-2fa', require('../middleware/auth').authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { otp } = req.body;
    const record = otpStore[userId];
    if (!record || !otp) {
      return res.status(400).json({ success: false, error: 'OTP not requested or missing.' });
    }
    if (Date.now() > record.expires) {
      delete otpStore[userId];
      return res.status(400).json({ success: false, error: 'OTP expired.' });
    }
    if (record.otp !== otp) {
      return res.status(400).json({ success: false, error: 'Invalid OTP.' });
    }
    delete otpStore[userId];
    res.status(200).json({ success: true, message: 'OTP verified.' });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Failed to verify OTP', details: err.message });
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
