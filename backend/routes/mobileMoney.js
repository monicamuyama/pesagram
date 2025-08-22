const express = require('express');
const { body, validationResult } = require('express-validator');
const router = express.Router();

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

// Supported mobile money providers in Uganda and East Africa
const MOBILE_MONEY_PROVIDERS = {
  MTN: {
    name: 'MTN Mobile Money',
    code: 'MTN',
    countries: ['UG', 'RW', 'ZM', 'GH'],
    currencies: ['UGX', 'RWF', 'ZMW', 'GHS']
  },
  AIRTEL: {
    name: 'Airtel Money',
    code: 'AIRTEL',
    countries: ['UG', 'KE', 'TZ', 'ZM'],
    currencies: ['UGX', 'KES', 'TZS', 'ZMW']
  },
  MPESA: {
    name: 'M-Pesa',
    code: 'MPESA',
    countries: ['KE', 'TZ'],
    currencies: ['KES', 'TZS']
  }
};

// GET /api/mobile-money/providers - Get supported mobile money providers
router.get('/providers', async (req, res, next) => {
  try {
    const { country } = req.query;
    
    let providers = Object.values(MOBILE_MONEY_PROVIDERS);
    
    if (country) {
      providers = providers.filter(provider => 
        provider.countries.includes(country.toUpperCase())
      );
    }

    res.status(200).json({
      success: true,
      message: 'Mobile money providers retrieved',
      data: {
        providers: providers.map(p => ({
          code: p.code,
          name: p.name,
          countries: p.countries,
          currencies: p.currencies
        }))
      }
    });

  } catch (error) {
    console.error('❌ Get mobile money providers error:', error.message);
    next(error);
  }
});

// POST /api/mobile-money/send - Send money to mobile money
router.post('/send', [
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

    // Validate provider supports currency
    const providerConfig = MOBILE_MONEY_PROVIDERS[provider];
    if (!providerConfig.currencies.includes(currency)) {
      return res.status(400).json({
        success: false,
        error: `${provider} does not support ${currency}`
      });
    }

    // In a real implementation, you would:
    // 1. Check user's wallet balance
    // 2. Create a transaction record
    // 3. Call mobile money provider API
    // 4. Handle callbacks/webhooks

    // For demo purposes, simulate the transaction
    const transactionId = `momo_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    const simulatedResponse = {
      transactionId,
      status: 'pending',
      phoneNumber: phoneNumber,
      amount: parseFloat(amount),
      currency,
      provider,
      description: description || 'Mobile money transfer',
      fee: Math.round(amount * 0.015 * 100) / 100, // 1.5% fee simulation
      estimatedDelivery: new Date(Date.now() + 5 * 60 * 1000).toISOString(), // 5 minutes
      createdAt: new Date().toISOString()
    };

    // TODO: Implement actual mobile money provider integration
    // Examples:
    // - MTN MoMo API: https://developer.mtn.com/
    // - Airtel Money API: https://developers.airtel.africa/
    // - M-Pesa API: https://developer.safaricom.co.ke/

    console.log(`✅ Mobile money transaction created: ${transactionId}`);

    res.status(201).json({
      success: true,
      message: 'Mobile money transfer initiated',
      data: simulatedResponse
    });

  } catch (error) {
    console.error('❌ Mobile money transfer error:', error.message);
    next(error);
  }
});

// GET /api/mobile-money/transaction/:id - Get mobile money transaction status
router.get('/transaction/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

    console.log(`📱 Checking mobile money transaction: ${id}`);

    // In a real implementation, query from database
    // For demo, simulate transaction status
    const simulatedTransaction = {
      transactionId: id,
      status: Math.random() > 0.3 ? 'completed' : 'pending',
      statusMessage: 'Transaction processed successfully',
      completedAt: new Date().toISOString(),
      receipt: `MM-${id.slice(-8).toUpperCase()}`
    };

    res.status(200).json({
      success: true,
      message: 'Transaction status retrieved',
      data: simulatedTransaction
    });

  } catch (error) {
    console.error('❌ Get mobile money transaction error:', error.message);
    next(error);
  }
});

// POST /api/mobile-money/webhook - Handle mobile money provider webhooks
router.post('/webhook', async (req, res, next) => {
  try {
    const { provider, transactionId, status, data } = req.body;

    console.log(`🔔 Mobile money webhook from ${provider}:`, {
      transactionId,
      status,
      timestamp: new Date().toISOString()
    });

    // In a real implementation:
    // 1. Verify webhook signature
    // 2. Update transaction status in database
    // 3. Send push notification to user
    // 4. Update wallet balances if needed

    res.status(200).json({
      success: true,
      message: 'Webhook processed'
    });

  } catch (error) {
    console.error('❌ Mobile money webhook error:', error.message);
    next(error);
  }
});

module.exports = router;
