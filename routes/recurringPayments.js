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

// In-memory storage for demo (use database in production)
const recurringPayments = new Map();

// Helper function to calculate next payment date
const calculateNextPayment = (frequency, lastPayment) => {
  const date = new Date(lastPayment);
  
  switch (frequency) {
    case 'daily':
      date.setDate(date.getDate() + 1);
      break;
    case 'weekly':
      date.setDate(date.getDate() + 7);
      break;
    case 'monthly':
      date.setMonth(date.getMonth() + 1);
      break;
    case 'yearly':
      date.setFullYear(date.getFullYear() + 1);
      break;
    default:
      throw new Error('Invalid frequency');
  }
  
  return date;
};

// POST /api/recurring-payments - Create recurring payment schedule
router.post('/', [
  body('recipientType').isIn(['address', 'phone', 'mobile_money']).withMessage('Valid recipient type required'),
  body('recipient').notEmpty().withMessage('Recipient is required'),
  body('amount').isNumeric().isFloat({ min: 0.01 }).withMessage('Valid amount required'),
  body('currency').isIn(['BTC', 'USDT', 'UGX', 'USD']).withMessage('Supported currency required'),
  body('frequency').isIn(['daily', 'weekly', 'monthly', 'yearly']).withMessage('Valid frequency required'),
  body('startDate').isISO8601().withMessage('Valid start date required'),
  body('endDate').optional().isISO8601().withMessage('Valid end date required'),
  body('maxPayments').optional().isInt({ min: 1 }).withMessage('Max payments must be positive integer'),
  body('description').optional().trim().isLength({ max: 200 })
], handleValidationErrors, async (req, res, next) => {
  try {
    const {
      recipientType,
      recipient,
      amount,
      currency,
      frequency,
      startDate,
      endDate,
      maxPayments,
      description
    } = req.body;
    
    const userId = req.user.userId;
    const scheduleId = `schedule_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Validate dates
    const start = new Date(startDate);
    const end = endDate ? new Date(endDate) : null;
    
    if (end && end <= start) {
      return res.status(400).json({
        success: false,
        error: 'End date must be after start date'
      });
    }

    const recurringPayment = {
      scheduleId,
      userId,
      recipientType,
      recipient,
      amount: parseFloat(amount),
      currency,
      frequency,
      startDate: start.toISOString(),
      endDate: end?.toISOString() || null,
      maxPayments: maxPayments || null,
      description: description || 'Recurring payment',
      status: 'active',
      paymentsCount: 0,
      nextPaymentDate: start.toISOString(),
      lastPaymentDate: null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    // Store in memory (use database in production)
    recurringPayments.set(scheduleId, recurringPayment);

    console.log(`📅 Recurring payment created: ${scheduleId} for user: ${userId}`);

    res.status(201).json({
      success: true,
      message: 'Recurring payment schedule created',
      data: {
        schedule: recurringPayment
      }
    });

  } catch (error) {
    console.error('❌ Create recurring payment error:', error.message);
    next(error);
  }
});

// GET /api/recurring-payments - Get user's recurring payments
router.get('/', async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { status } = req.query;

    console.log(`📅 Fetching recurring payments for user: ${userId}`);

    // Filter payments for this user
    const userPayments = Array.from(recurringPayments.values())
      .filter(payment => payment.userId === userId)
      .filter(payment => !status || payment.status === status)
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    res.status(200).json({
      success: true,
      message: 'Recurring payments retrieved',
      data: {
        payments: userPayments,
        total: userPayments.length
      }
    });

  } catch (error) {
    console.error('❌ Get recurring payments error:', error.message);
    next(error);
  }
});

// GET /api/recurring-payments/:scheduleId - Get specific recurring payment
router.get('/:scheduleId', async (req, res, next) => {
  try {
    const { scheduleId } = req.params;
    const userId = req.user.userId;

    const payment = recurringPayments.get(scheduleId);
    
    if (!payment) {
      return res.status(404).json({
        success: false,
        error: 'Recurring payment not found'
      });
    }

    if (payment.userId !== userId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Recurring payment retrieved',
      data: {
        schedule: payment
      }
    });

  } catch (error) {
    console.error('❌ Get recurring payment error:', error.message);
    next(error);
  }
});

// PUT /api/recurring-payments/:scheduleId - Update recurring payment
router.put('/:scheduleId', [
  body('amount').optional().isNumeric().isFloat({ min: 0.01 }),
  body('frequency').optional().isIn(['daily', 'weekly', 'monthly', 'yearly']),
  body('endDate').optional().isISO8601(),
  body('maxPayments').optional().isInt({ min: 1 }),
  body('description').optional().trim().isLength({ max: 200 })
], handleValidationErrors, async (req, res, next) => {
  try {
    const { scheduleId } = req.params;
    const userId = req.user.userId;
    const updates = req.body;

    const payment = recurringPayments.get(scheduleId);
    
    if (!payment) {
      return res.status(404).json({
        success: false,
        error: 'Recurring payment not found'
      });
    }

    if (payment.userId !== userId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }

    if (payment.status !== 'active') {
      return res.status(400).json({
        success: false,
        error: 'Cannot update inactive recurring payment'
      });
    }

    // Apply updates
    Object.keys(updates).forEach(key => {
      if (updates[key] !== undefined) {
        payment[key] = updates[key];
      }
    });
    
    payment.updatedAt = new Date().toISOString();

    // Recalculate next payment if frequency changed
    if (updates.frequency && payment.lastPaymentDate) {
      payment.nextPaymentDate = calculateNextPayment(
        payment.frequency, 
        payment.lastPaymentDate
      ).toISOString();
    }

    recurringPayments.set(scheduleId, payment);

    console.log(`📅 Recurring payment updated: ${scheduleId}`);

    res.status(200).json({
      success: true,
      message: 'Recurring payment updated',
      data: {
        schedule: payment
      }
    });

  } catch (error) {
    console.error('❌ Update recurring payment error:', error.message);
    next(error);
  }
});

// DELETE /api/recurring-payments/:scheduleId - Cancel recurring payment
router.delete('/:scheduleId', async (req, res, next) => {
  try {
    const { scheduleId } = req.params;
    const userId = req.user.userId;

    const payment = recurringPayments.get(scheduleId);
    
    if (!payment) {
      return res.status(404).json({
        success: false,
        error: 'Recurring payment not found'
      });
    }

    if (payment.userId !== userId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }

    // Mark as cancelled instead of deleting
    payment.status = 'cancelled';
    payment.updatedAt = new Date().toISOString();
    recurringPayments.set(scheduleId, payment);

    console.log(`📅 Recurring payment cancelled: ${scheduleId}`);

    res.status(200).json({
      success: true,
      message: 'Recurring payment cancelled',
      data: {
        schedule: payment
      }
    });

  } catch (error) {
    console.error('❌ Cancel recurring payment error:', error.message);
    next(error);
  }
});

// POST /api/recurring-payments/process - Process due payments (internal endpoint for scheduler)
router.post('/process', async (req, res, next) => {
  try {
    // This endpoint would be called by a scheduler (cron job, etc.)
    const now = new Date();
    const duePayments = Array.from(recurringPayments.values())
      .filter(payment => 
        payment.status === 'active' &&
        new Date(payment.nextPaymentDate) <= now
      );

    console.log(`📅 Processing ${duePayments.length} due payments`);

    const processedPayments = [];

    for (const payment of duePayments) {
      try {
        // In a real implementation:
        // 1. Check user's wallet balance
        // 2. Execute the payment based on recipientType
        // 3. Update payment counts and dates
        // 4. Handle errors and retries

        // Simulate payment processing
        const isSuccessful = Math.random() > 0.1; // 90% success rate

        if (isSuccessful) {
          payment.paymentsCount += 1;
          payment.lastPaymentDate = now.toISOString();
          
          // Check if we've reached the end
          const shouldStop = 
            (payment.maxPayments && payment.paymentsCount >= payment.maxPayments) ||
            (payment.endDate && now >= new Date(payment.endDate));

          if (shouldStop) {
            payment.status = 'completed';
            payment.nextPaymentDate = null;
          } else {
            payment.nextPaymentDate = calculateNextPayment(
              payment.frequency, 
              payment.lastPaymentDate
            ).toISOString();
          }

          payment.updatedAt = now.toISOString();
          recurringPayments.set(payment.scheduleId, payment);

          processedPayments.push({
            scheduleId: payment.scheduleId,
            status: 'processed',
            amount: payment.amount,
            currency: payment.currency
          });
        } else {
          processedPayments.push({
            scheduleId: payment.scheduleId,
            status: 'failed',
            error: 'Payment processing failed'
          });
        }

      } catch (error) {
        console.error(`❌ Failed to process payment ${payment.scheduleId}:`, error.message);
        processedPayments.push({
          scheduleId: payment.scheduleId,
          status: 'error',
          error: error.message
        });
      }
    }

    res.status(200).json({
      success: true,
      message: 'Payment processing completed',
      data: {
        processed: processedPayments.length,
        results: processedPayments
      }
    });

  } catch (error) {
    console.error('❌ Process recurring payments error:', error.message);
    next(error);
  }
});

module.exports = router;
