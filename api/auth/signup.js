const { connectToDatabase } = require('../../lib/database');
const User = require('../../models/User');
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const bitnobService = require('../../services/bitnobService');

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
const validateSignup = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Password must contain uppercase, lowercase, number, and special character'),
  body('firstName').trim().isLength({ min: 1, max: 50 }).withMessage('First name required (1-50 characters)'),
  body('lastName').trim().isLength({ min: 1, max: 50 }).withMessage('Last name required (1-50 characters)'),
  body('phone').isMobilePhone().withMessage('Valid phone number required'),
  body('countryCode').optional().isLength({ min: 2, max: 4 }).withMessage('Valid country code required')
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
    await Promise.all(validateSignup.map(validation => validation.run(req)));
    const validationError = handleValidationErrors(req, res);
    if (validationError) return;

    const { email, password, firstName, lastName, phone, countryCode } = req.body;

    console.log(`🔐 Registration attempt for email: ${email}`);

    // Check if user already exists
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      return res.status(409).json({
        success: false,
        error: 'User already exists with this email'
      });
    }

    // Create customer in Bitnob first
    let bitnobCustomer = null;
    try {
      const bitnobCustomerData = {
        email,
        firstName,
        lastName,
        phone,
        countryCode: countryCode || '+234'
      };

      bitnobCustomer = await bitnobService.createCustomer(bitnobCustomerData);
      console.log(`✅ Bitnob customer created:`, bitnobCustomer.data);
    } catch (bitnobError) {
      console.warn(`⚠️ Failed to create Bitnob customer:`, bitnobError.message);
      // Continue with user creation even if Bitnob fails
    }

    // Create user in database
    const userData = {
      email,
      password, // Will be hashed by pre-save middleware
      firstName,
      lastName,
      phone,
      countryCode: countryCode || '+234',
      bitnobCustomerId: bitnobCustomer?.data?.id,
      emailVerified: false,
      kycStatus: 'pending'
    };

    const newUser = new User(userData);
    
    // Generate email verification token
    const emailVerificationToken = newUser.generateEmailVerificationToken();
    
    await newUser.save();

    // Generate JWT token
    const token = generateToken({
      userId: newUser._id,
      email: newUser.email,
      firstName: newUser.firstName,
      lastName: newUser.lastName,
      emailVerified: newUser.emailVerified
    });

    console.log(`✅ Registration successful for: ${email}`);

    // TODO: Send email verification
    // await sendVerificationEmail(email, emailVerificationToken);

    res.status(201).json({
      success: true,
      message: 'User registered successfully. Please verify your email.',
      data: {
        user: newUser.toJSON(),
        token: token,
        requiresEmailVerification: true
      }
    });

  } catch (error) {
    console.error('❌ Registration error:', error);
    
    // Handle specific MongoDB errors
    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        error: 'User with this email already exists'
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
