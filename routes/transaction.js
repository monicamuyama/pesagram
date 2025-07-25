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

// POST /api/transaction/lightning/invoice - Create Lightning Invoice
router.post('/lightning/invoice', [
  body('amount').isNumeric().isInt({ min: 1 }).withMessage('Amount (in sats) is required'),
  body('description').optional().isString().isLength({ max: 200 }),
  body('expiry').optional().isInt({ min: 60, max: 86400 }) // 1 min to 24 hours
], handleValidationErrors, async (req, res, next) => {
  try {
    const { amount, description, expiry } = req.body;
    const userId = req.user.userId;
    const customerId = req.user.bitnobCustomerId; // Assumes user object has bitnobCustomerId

    const invoiceData = {
      customerId,
      amount: parseInt(amount),
      description,
      expiry
    };

    const invoiceResponse = await require('../services/bitnobService_improved').createLightningInvoice(invoiceData);

    res.status(201).json({
      success: true,
      message: 'Lightning invoice created',
      data: invoiceResponse
    });
  } catch (error) {
    console.error('❌ Create Lightning invoice error:', error.message);
    next(error);
  }
});

// POST /api/transaction/lightning/pay - Pay Lightning Invoice
router.post('/lightning/pay', [
  body('invoice').notEmpty().withMessage('Lightning invoice is required')
], handleValidationErrors, async (req, res, next) => {
  try {
    const { invoice } = req.body;
    const userId = req.user.userId;
    const customerId = req.user.bitnobCustomerId; // Assumes user object has bitnobCustomerId

    const paymentData = {
      customerId,
      invoice
    };

    const payResponse = await require('../services/bitnobService_improved').payLightningInvoice(paymentData);

    res.status(200).json({
      success: true,
      message: 'Lightning invoice paid',
      data: payResponse
    });
  } catch (error) {
    console.error('❌ Pay Lightning invoice error:', error.message);
    next(error);
  }
});

// POST /api/transaction/mobile-money - Send to mobile money
router.post('/mobile-money', [
  body('phoneNumber').isMobilePhone().withMessage('Valid phone number required'),
  body('amount').isNumeric().isFloat({ min: 0.01 }).withMessage('Valid amount required'),
  body('currency').isIn(['UGX', 'KES', 'TZS', 'RWF', 'ZMW', 'GHS']).withMessage('Supported currency required'),
  body('provider').isIn(['MTN', 'AIRTEL', 'MPESA']).withMessage('Supported provider required'),
  body('description').optional().trim().isLength({ max: 200 })
], handleValidationErrors, async (req, res, next) => {
  try {
    const { phoneNumber, amount, currency, provider, description } = req.body;
    const userId = req.user.userId;

    console.log(`📱 Mobile money transfer: ${amount} ${currency} to ${phoneNumber} via ${provider}`);

    // Use the mobile money service
    const mobileMoneyService = require('./mobileMoney');
    const result = await mobileMoneyService.sendToMobileMoney({
      phoneNumber,
      amount,
      currency,
      provider,
      description,
      userId
    });

    res.status(201).json({
      success: true,
      message: 'Mobile money transfer initiated',
      data: result
    });

  } catch (error) {
    console.error('❌ Mobile money transfer error:', error.message);
    next(error);
  }
});

module.exports = router;
