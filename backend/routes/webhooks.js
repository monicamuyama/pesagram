const express = require('express');
const crypto = require('crypto');
const User = require('../models/User');

const router = express.Router();

// Webhook signature verification middleware
const verifyWebhookSignature = (req, res, next) => {
  try {
    const signature = req.headers['x-bitnob-signature'];
    const timestamp = req.headers['x-bitnob-timestamp'];
    
    if (!signature || !timestamp) {
      return res.status(400).json({
        success: false,
        error: 'Missing webhook signature or timestamp'
      });
    }

    // Verify timestamp is within 5 minutes to prevent replay attacks
    const currentTime = Math.floor(Date.now() / 1000);
    const webhookTime = parseInt(timestamp);
    if (Math.abs(currentTime - webhookTime) > 300) {
      return res.status(400).json({
        success: false,
        error: 'Webhook timestamp too old'
      });
    }

    // Verify signature
    const webhookSecret = process.env.BITNOB_WEBHOOK_SECRET;
    const payload = JSON.stringify(req.body);
    const expectedSignature = crypto
      .createHmac('sha256', webhookSecret)
      .update(timestamp + payload)
      .digest('hex');

    if (signature !== expectedSignature) {
      return res.status(400).json({
        success: false,
        error: 'Invalid webhook signature'
      });
    }

    next();
  } catch (error) {
    console.error('❌ Webhook signature verification error:', error);
    return res.status(400).json({
      success: false,
      error: 'Webhook verification failed'
    });
  }
};

// POST /api/webhooks/bitnob - Handle Bitnob webhooks
router.post('/bitnob', verifyWebhookSignature, async (req, res) => {
  try {
    const { event, data } = req.body;

    console.log(`🔔 Received Bitnob webhook: ${event}`, data);

    switch (event) {
      case 'transaction.completed':
        await handleTransactionCompleted(data);
        break;
      
      case 'transaction.failed':
        await handleTransactionFailed(data);
        break;
      
      case 'invoice.paid':
        await handleInvoicePaid(data);
        break;
      
      case 'invoice.expired':
        await handleInvoiceExpired(data);
        break;
      
      case 'wallet.credited':
        await handleWalletCredited(data);
        break;
      
      case 'wallet.debited':
        await handleWalletDebited(data);
        break;
      
      case 'kyc.approved':
        await handleKYCApproved(data);
        break;
      
      case 'kyc.rejected':
        await handleKYCRejected(data);
        break;
      
      default:
        console.log(`⚠️ Unhandled webhook event: ${event}`);
    }

    res.status(200).json({
      success: true,
      message: 'Webhook processed successfully'
    });

  } catch (error) {
    console.error('❌ Webhook processing error:', error);
    res.status(500).json({
      success: false,
      error: 'Webhook processing failed'
    });
  }
});

// Webhook event handlers
async function handleTransactionCompleted(data) {
  try {
    console.log(`✅ Transaction completed: ${data.id}`);
    
    // TODO: Update transaction status in database
    // await Transaction.update(
    //   { 
    //     status: 'completed',
    //     completedAt: new Date(),
    //     bitnobTransactionId: data.id
    //   },
    //   { where: { bitnobTransactionId: data.id } }
    // );

    // TODO: Update wallet balance
    // await updateWalletBalance(data.wallet_id);

    // TODO: Send push notification to user
    // await sendPushNotification(data.customer_id, {
    //   title: 'Transaction Completed',
    //   body: `Your ${data.currency} transaction has been completed`,
    //   type: 'transaction_completed',
    //   data: { transactionId: data.id }
    // });

    // TODO: Send email notification
    // await sendEmailNotification(data.customer_email, 'transaction_completed', data);

  } catch (error) {
    console.error('❌ Error handling transaction completed:', error);
  }
}

async function handleTransactionFailed(data) {
  try {
    console.log(`❌ Transaction failed: ${data.id}`);
    
    // TODO: Update transaction status in database
    // await Transaction.update(
    //   { 
    //     status: 'failed',
    //     failureReason: data.reason,
    //     failedAt: new Date()
    //   },
    //   { where: { bitnobTransactionId: data.id } }
    // );

    // TODO: Send push notification to user
    // await sendPushNotification(data.customer_id, {
    //   title: 'Transaction Failed',
    //   body: `Your ${data.currency} transaction has failed: ${data.reason}`,
    //   type: 'transaction_failed',
    //   data: { transactionId: data.id }
    // });

  } catch (error) {
    console.error('❌ Error handling transaction failed:', error);
  }
}

async function handleInvoicePaid(data) {
  try {
    console.log(`💰 Invoice paid: ${data.id}`);
    
    // TODO: Update invoice status
    // TODO: Credit user wallet
    // TODO: Send notification

  } catch (error) {
    console.error('❌ Error handling invoice paid:', error);
  }
}

async function handleInvoiceExpired(data) {
  try {
    console.log(`⏰ Invoice expired: ${data.id}`);
    
    // TODO: Update invoice status
    // TODO: Send notification

  } catch (error) {
    console.error('❌ Error handling invoice expired:', error);
  }
}

async function handleWalletCredited(data) {
  try {
    console.log(`💰 Wallet credited: ${data.wallet_id}`);
    
    // TODO: Update wallet balance in database
    // await UserWallet.update(
    //   { balance: data.new_balance },
    //   { where: { bitnobWalletId: data.wallet_id } }
    // );

    // TODO: Create transaction record
    // TODO: Send notification

  } catch (error) {
    console.error('❌ Error handling wallet credited:', error);
  }
}

async function handleWalletDebited(data) {
  try {
    console.log(`💸 Wallet debited: ${data.wallet_id}`);
    
    // TODO: Update wallet balance in database
    // TODO: Create transaction record
    // TODO: Send notification

  } catch (error) {
    console.error('❌ Error handling wallet debited:', error);
  }
}

async function handleKYCApproved(data) {
  try {
    console.log(`✅ KYC approved for customer: ${data.customer_id}`);
    await User.findOneAndUpdate(
      { bitnobCustomerId: data.customer_id },
      { kycStatus: 'approved', kycRejectionReason: null }
    );
    // TODO: Send congratulations notification
  } catch (error) {
    console.error('❌ Error handling KYC approved:', error);
  }
}

async function handleKYCRejected(data) {
  try {
    console.log(`❌ KYC rejected for customer: ${data.customer_id}`);
    await User.findOneAndUpdate(
      { bitnobCustomerId: data.customer_id },
      { kycStatus: 'rejected', kycRejectionReason: data.reason || 'Unknown reason' }
    );
    // TODO: Send notification with next steps
  } catch (error) {
    console.error('❌ Error handling KYC rejected:', error);
  }
}

module.exports = router;
