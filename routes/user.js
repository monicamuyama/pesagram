const express = require('express');
const { body, validationResult } = require('express-validator');

const router = express.Router();

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

// GET /api/user/profile - Get user profile
router.get('/profile', async (req, res, next) => {
  try {
    const user = req.user;
    
    console.log(`👤 Fetching profile for user: ${user.userId}`);

    // Return user information from JWT token
    // In a full implementation, you might fetch additional data from a database
    res.status(200).json({
      success: true,
      message: 'Profile retrieved successfully',
      data: {
        user: {
          id: user.userId,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          fullName: `${user.firstName} ${user.lastName}`
        }
      }
    });

  } catch (error) {
    console.error(' Get profile error:', error.message);
    next(error);
  }
});

// PUT /api/user/profile - Update user profile
router.put('/profile', [
  body('firstName').optional().trim().isLength({ min: 1 }).withMessage('First name cannot be empty'),
  body('lastName').optional().trim().isLength({ min: 1 }).withMessage('Last name cannot be empty'),
  body('phone').optional().trim().isLength({ min: 10 }).withMessage('Valid phone number required')
], handleValidationErrors, async (req, res, next) => {
  try {
    const { firstName, lastName, phone } = req.body;
    const userId = req.user.userId;

    console.log(`👤 Updating profile for user: ${userId}`);

    // In a full implementation, you would update the user in the database
    // and possibly sync with Bitnob API
    
    const updatedUser = {
      id: userId,
      email: req.user.email,
      firstName: firstName || req.user.firstName,
      lastName: lastName || req.user.lastName,
      phone: phone || req.user.phone,
      updatedAt: new Date().toISOString()
    };

    console.log(`✅ Profile updated successfully for user: ${userId}`);

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: updatedUser
      }
    });

  } catch (error) {
    console.error(' Update profile error:', error.message);
    next(error);
  }
});

// GET /api/user/settings - Get user settings
router.get('/settings', async (req, res, next) => {
  try {
    const userId = req.user.userId;
    
    console.log(`⚙️ Fetching settings for user: ${userId}`);

    // Default user settings
    const settings = {
      notifications: {
        email: true,
        push: true,
        sms: false
      },
      security: {
        twoFactorAuth: false,
        biometricAuth: false
      },
      preferences: {
        currency: 'USD',
        language: 'en',
        theme: 'light'
      }
    };

    res.status(200).json({
      success: true,
      message: 'Settings retrieved successfully',
      data: settings
    });

  } catch (error) {
    console.error('❌ Get settings error:', error.message);
    next(error);
  }
});

// PUT /api/user/settings - Update user settings
router.put('/settings', [
  body('notifications.email').optional().isBoolean(),
  body('notifications.push').optional().isBoolean(),
  body('notifications.sms').optional().isBoolean(),
  body('security.twoFactorAuth').optional().isBoolean(),
  body('security.biometricAuth').optional().isBoolean(),
  body('preferences.currency').optional().isIn(['USD', 'EUR', 'GBP', 'NGN', 'BTC', 'ETH']),
  body('preferences.language').optional().isIn(['en', 'fr', 'es']),
  body('preferences.theme').optional().isIn(['light', 'dark'])
], handleValidationErrors, async (req, res, next) => {
  try {
    const settings = req.body;
    const userId = req.user.userId;

    console.log(`⚙️ Updating settings for user: ${userId}`);

    // In a full implementation, you would save settings to database
    
    console.log(`✅ Settings updated successfully for user: ${userId}`);

    res.status(200).json({
      success: true,
      message: 'Settings updated successfully',
      data: settings
    });

  } catch (error) {
    console.error('❌ Update settings error:', error.message);
    next(error);
  }
});

module.exports = router;
