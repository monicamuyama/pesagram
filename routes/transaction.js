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

// GET /api/transaction - Get transaction history
router.get('/', async (req, res, next) => {
  try {
    const { walletId, page = 1, limit = 20, status, type } = req.query;
    const userId = req.user.userId;

    console.log(` Fetching transactions for user: ${userId}, wallet: ${walletId}`);

    if (!walletId) {
      return res.status(400).json({
        error: 'Wallet ID is required',
        message: 'Please provide a walletId query parameter'
      });
    }

    const params = {
      page: parseInt(page),
      limit: parseInt(limit),
      ...(status && { status }),
      ...(type && { type })
    };

    const transactionsResponse = await bitnobService.getTransactionHistory(walletId, params);

    res.status(200).json({
      success: true,
      message: 'Transaction history retrieved successfully',
      data: transactionsResponse
    });

  } catch (error) {
    console.error('Get transactions error:', error.message);
    next(error);
  }
});

// GET /api/transaction/:transactionId - Get transaction details
router.get('/:transactionId', async (req, res, next) => {
  try {
    const { transactionId } = req.params;
    const userId = req.user.userId;

    console.log(` Fetching transaction details: ${transactionId} for user: ${userId}`);

    const transactionResponse = await bitnobService.getTransaction(transactionId);

    res.status(200).json({
      success: true,
      message: 'Transaction details retrieved successfully',
      data: transactionResponse
    });

  } catch (error) {
    console.error(' Get transaction error:', error.message);
    next(error);
  }
});

// POST /api/transaction/send - Send money
router.post('/send', [
  body('fromWalletId').notEmpty().withMessage('Source wallet ID is required'),
  body('toAddress').notEmpty().withMessage('Recipient address is required'),
  body('amount').isNumeric().isFloat({ min: 0.01 }).withMessage('Valid amount is required'),
  body('currency').notEmpty().withMessage('Currency is required'),
  body('description').optional().trim().isLength({ max: 200 }).withMessage('Description must be max 200 characters')
], handleValidationErrors, async (req, res, next) => {
  try {
    const { fromWalletId, toAddress, amount, currency, description } = req.body;
    const userId = req.user.userId;

    console.log(`💸 Sending ${amount} ${currency} from wallet: ${fromWalletId} to: ${toAddress}`);

    const transactionData = {
      userId,
      fromWalletId,
      toAddress,
      amount: parseFloat(amount),
      currency: currency.toUpperCase(),
      description: description || 'Money transfer',
      type: 'send'
    };

    const sendResponse = await bitnobService.sendMoney(transactionData);

    console.log(`✅ Money sent successfully: ${amount} ${currency}`);

    res.status(200).json({
      success: true,
      message: 'Money sent successfully',
      data: sendResponse
    });

  } catch (error) {
    console.error('❌ Send money error:', error.message);
    next(error);
  }
});

// POST /api/transaction/swap - Currency swap
router.post('/swap', [
  body('fromWalletId').notEmpty().withMessage('Source wallet ID is required'),
  body('toWalletId').notEmpty().withMessage('Destination wallet ID is required'),
  body('fromAmount').isNumeric().isFloat({ min: 0.01 }).withMessage('Valid from amount is required'),
  body('fromCurrency').notEmpty().withMessage('From currency is required'),
  body('toCurrency').notEmpty().withMessage('To currency is required')
], handleValidationErrors, async (req, res, next) => {
  try {
    const { fromWalletId, toWalletId, fromAmount, fromCurrency, toCurrency } = req.body;
    const userId = req.user.userId;

    console.log(`🔄 Swapping ${fromAmount} ${fromCurrency} to ${toCurrency}`);

    const swapData = {
      userId,
      fromWalletId,
      toWalletId,
      fromAmount: parseFloat(fromAmount),
      fromCurrency: fromCurrency.toUpperCase(),
      toCurrency: toCurrency.toUpperCase(),
      type: 'swap'
    };

    const swapResponse = await bitnobService.swapCurrency(swapData);

    console.log(`✅ Currency swap successful: ${fromCurrency} to ${toCurrency}`);

    res.status(200).json({
      success: true,
      message: 'Currency swap completed successfully',
      data: swapResponse
    });

  } catch (error) {
    console.error('❌ Currency swap error:', error.message);
    next(error);
  }
});

module.exports = router;
