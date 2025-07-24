const { connectToDatabase } = require('../../lib/database');
const Wallet = require('../../models/Wallet');
const User = require('../../models/User');
const bitnobService = require('../../services/bitnobService');
const jwt = require('jsonwebtoken');

// JWT Authentication middleware
const authenticateToken = async (req) => {
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    throw new Error('Access token required');
  }

  const decoded = jwt.verify(token, process.env.JWT_SECRET);
  return decoded;
};

module.exports = async (req, res) => {
  // Handle CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    // Connect to database
    await connectToDatabase();

    // Authenticate user
    const user = await authenticateToken(req);
    const userId = user.userId;

    if (req.method === 'GET') {
      // Get user wallets
      console.log(`💰 Fetching wallets for user: ${userId}`);

      const wallets = await Wallet.findByUserId(userId);

      // If no wallets exist, try to sync from Bitnob
      if (wallets.length === 0) {
        try {
          const userDoc = await User.findById(userId);
          if (userDoc && userDoc.bitnobCustomerId) {
            // This would require implementing wallet sync from Bitnob
            console.log(`🔄 No local wallets found, attempting sync for customer: ${userDoc.bitnobCustomerId}`);
          }
        } catch (syncError) {
          console.warn('⚠️ Failed to sync wallets from Bitnob:', syncError.message);
        }
      }

      res.status(200).json({
        success: true,
        message: 'Wallets retrieved successfully',
        data: {
          wallets: wallets,
          count: wallets.length
        }
      });

    } else if (req.method === 'POST') {
      // Create new wallet
      const { currency, label, walletType } = req.body;

      if (!currency) {
        return res.status(400).json({
          success: false,
          error: 'Currency is required'
        });
      }

      console.log(`💰 Creating ${currency} wallet for user: ${userId}`);

      // Check if user already has a wallet for this currency
      const existingWallet = await Wallet.findOne({
        userId,
        currency: currency.toUpperCase(),
        isActive: true
      });

      if (existingWallet) {
        return res.status(409).json({
          success: false,
          error: `You already have a ${currency.toUpperCase()} wallet`
        });
      }

      // Get user's Bitnob customer ID
      const userDoc = await User.findById(userId);
      if (!userDoc || !userDoc.bitnobCustomerId) {
        return res.status(400).json({
          success: false,
          error: 'User not properly linked to Bitnob customer'
        });
      }

      let bitnobWalletId = null;

      // Create wallet in Bitnob (if supported currency)
      if (['BTC', 'USD'].includes(currency.toUpperCase())) {
        try {
          const walletData = {
            currency: currency.toUpperCase(),
            label: label || `${currency.toUpperCase()} Wallet`,
            customerId: userDoc.bitnobCustomerId
          };

          const bitnobResponse = await bitnobService.createCryptoWallet(walletData);
          bitnobWalletId = bitnobResponse.data?.id;
          
          console.log(`✅ Bitnob wallet created: ${bitnobWalletId}`);
        } catch (bitnobError) {
          console.warn(`⚠️ Failed to create Bitnob wallet:`, bitnobError.message);
          // Continue with local wallet creation
        }
      }

      // Create wallet in local database
      const newWallet = new Wallet({
        userId,
        bitnobWalletId,
        currency: currency.toUpperCase(),
        walletType: walletType || 'bitcoin',
        label: label || `${currency.toUpperCase()} Wallet`,
        isDefault: !existingWallet, // First wallet of this currency becomes default
        metadata: {
          createdVia: 'app'
        }
      });

      await newWallet.save();

      console.log(`✅ Wallet created successfully: ${currency}`);

      res.status(201).json({
        success: true,
        message: 'Wallet created successfully',
        data: {
          wallet: newWallet.toJSON()
        }
      });

    } else {
      res.status(405).json({
        success: false,
        error: 'Method not allowed'
      });
    }

  } catch (error) {
    console.error('❌ Wallet operation error:', error);

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        error: 'Invalid token'
      });
    }

    if (error.message === 'Access token required') {
      return res.status(401).json({
        success: false,
        error: 'Access token required'
      });
    }

    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
