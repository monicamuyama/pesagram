const express = require('express');
const { body, validationResult } = require('express-validator');
const bitnobService = require('../services/bitnobService');

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

// GET /api/wallet - Get user wallets
router.get('/', async (req, res, next) => {
  try {
    const userId = req.user.userId;
    console.log(`💰 Fetching wallets for user: ${userId}`);

    const walletsResponse = await bitnobService.getWallets(userId);

    res.status(200).json({
      success: true,
      message: 'Wallets retrieved successfully',
      data: {
        wallets: walletsResponse.data || walletsResponse || []
      }
    });

  } catch (error) {
    console.error('❌ Get wallets error:', error.message);
    next(error);
  }
});

// POST /api/wallet - Create new wallet
router.post('/', [
  body('currency').notEmpty().withMessage('Currency is required'),
  body('label').optional().trim().isLength({ min: 1, max: 50 }).withMessage('Label must be 1-50 characters')
], handleValidationErrors, async (req, res, next) => {
  try {
    const { currency, label } = req.body;
    const userId = req.user.userId;

    console.log(`💰 Creating ${currency} wallet for user: ${userId}`);

    const walletData = {
      userId,
      currency: currency.toUpperCase(),
      label: label || `${currency.toUpperCase()} Wallet`,
      type: 'standard' // Default wallet type
    };

    const walletResponse = await bitnobService.createWallet(walletData);

    console.log(`✅ Wallet created successfully: ${currency}`);

    res.status(201).json({
      success: true,
      message: 'Wallet created successfully',
      data: walletResponse
    });

  } catch (error) {
    console.error('❌ Create wallet error:', error.message);
    next(error);
  }
});

// GET /api/wallet/:walletId/balance - Get wallet balance
router.get('/:walletId/balance', async (req, res, next) => {
  try {
    const { walletId } = req.params;
    const userId = req.user.userId;

    console.log(`💰 Fetching balance for wallet: ${walletId}, user: ${userId}`);

    const balanceResponse = await bitnobService.getWalletBalance(walletId);

    res.status(200).json({
      success: true,
      message: 'Balance retrieved successfully',
      data: balanceResponse
    });

  } catch (error) {
    console.error('❌ Get balance error:', error.message);
    next(error);
  }
});

// GET /api/wallet/rates - Get exchange rates
router.get('/rates', async (req, res, next) => {
  try {
    const { base = 'USD' } = req.query;
    
    console.log(`📊 Fetching exchange rates with base: ${base}`);

    const ratesResponse = await bitnobService.getExchangeRates(base);

    res.status(200).json({
      success: true,
      message: 'Exchange rates retrieved successfully',
      data: ratesResponse
    });

  } catch (error) {
    console.error('❌ Get rates error:', error.message);
    next(error);
  }
});

module.exports = router;
