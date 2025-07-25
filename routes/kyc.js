const express = require('express');
const { body, validationResult } = require('express-validator');
const { authenticateToken } = require('../middleware/auth');
const User = require('../models/User');
const bitnobService = require('../services/bitnobService');

const router = express.Router();

// POST /api/kyc/submit - User submits KYC documents
router.post('/submit', authenticateToken, [
  body('idType').notEmpty().withMessage('ID type is required'),
  body('idNumber').notEmpty().withMessage('ID number is required'),
  body('idImage').notEmpty().withMessage('ID image (base64) is required'),
  body('selfieImage').notEmpty().withMessage('Selfie image (base64) is required'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, error: 'Validation failed', details: errors.array() });
  }
  try {
    const userId = req.user.userId;
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });
    if (!user.bitnobCustomerId) return res.status(400).json({ success: false, error: 'User not linked to Bitnob' });

    // Call Bitnob KYC API (pseudo, adapt to real Bitnob API)
    const kycPayload = {
      customerId: user.bitnobCustomerId,
      idType: req.body.idType,
      idNumber: req.body.idNumber,
      idImage: req.body.idImage, // base64
      selfieImage: req.body.selfieImage, // base64
    };
    let bitnobResponse;
    try {
      bitnobResponse = await bitnobService.submitKYC(kycPayload);
    } catch (err) {
      return res.status(502).json({ success: false, error: 'Failed to submit KYC to Bitnob', details: err.message });
    }
    user.kycStatus = 'in_review';
    await user.save();
    res.status(200).json({ success: true, message: 'KYC submitted successfully', data: { kycStatus: user.kycStatus, bitnobResponse } });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Internal server error', details: err.message });
  }
});

// GET /api/kyc/status - Get current KYC status
router.get('/status', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, error: 'User not found' });
    res.status(200).json({
      success: true,
      data: {
        kycStatus: user.kycStatus,
        kycRejectionReason: user.kycRejectionReason || null
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Internal server error', details: err.message });
  }
});

module.exports = router; 