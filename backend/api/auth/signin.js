const { connectToDatabase } = require('../../lib/database');
const User = require('../../models/User');
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');

// Helper function to handle validation errors
const handleValidationErrors = (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      error: 'Validation failed',
      details: errors.array()
    });
  }
  return null;
};

// Validation rules
const validateSignin = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').notEmpty().withMessage('Password required')
];

// Generate JWT token
const generateToken = (payload) => {
  return jwt.sign(
    payload,
    process.env.JWT_SECRET,
    { 
      expiresIn: process.env.JWT_EXPIRES_IN || '24h',
      issuer: 'pesagram-api'
    }
  );
};

module.exports = async (req, res) => {
  // Handle CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({
      success: false,
      error: 'Method not allowed'
    });
  }

  try {
    // Connect to database
    await connectToDatabase();

    // Validate input
    await Promise.all(validateSignin.map(validation => validation.run(req)));
    const validationError = handleValidationErrors(req, res);
    if (validationError) return;

    const { email, password } = req.body;

    console.log(`🔐 Login attempt for email: ${email}`);

    // Find user by email
    const user = await User.findByEmail(email);
    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'Invalid email or password'
      });
    }

    // Check if account is locked
    if (user.isLocked) {
      return res.status(423).json({
        success: false,
        error: 'Account temporarily locked due to too many failed login attempts. Please try again later.'
      });
    }

    // Check if account is suspended
    if (user.status === 'suspended') {
      return res.status(403).json({
        success: false,
        error: 'Account suspended. Please contact support.'
      });
    }

    if (user.status === 'banned') {
      return res.status(403).json({
        success: false,
        error: 'Account has been banned. Please contact support.'
      });
    }

    // Verify password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      // Increment login attempts
      await user.incLoginAttempts();
      
      return res.status(401).json({
        success: false,
        error: 'Invalid email or password'
      });
    }

    // Reset login attempts on successful login
    if (user.loginAttempts > 0) {
      await user.resetLoginAttempts();
    }

    // Update last login info
    user.lastLoginAt = new Date();
    user.lastLoginIP = req.headers['x-forwarded-for'] || req.connection.remoteAddress;
    await user.save();

    // Generate JWT token
    const token = generateToken({
      userId: user._id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      emailVerified: user.emailVerified
    });

    console.log(`✅ Login successful for: ${email}`);

    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        user: user.toJSON(),
        token: token
      }
    });

  } catch (error) {
    console.error('❌ Login error:', error);
    
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
