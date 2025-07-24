const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  walletId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Wallet',
    required: true,
    index: true
  },
  bitnobTransactionId: {
    type: String,
    sparse: true,
    index: true
  },
  type: {
    type: String,
    required: true,
    enum: ['send', 'receive', 'swap', 'deposit', 'withdrawal', 'fee'],
    index: true
  },
  subType: {
    type: String,
    enum: ['bitcoin_onchain', 'lightning', 'bank_transfer', 'card_payment', 'internal_transfer']
  },
  status: {
    type: String,
    required: true,
    enum: ['pending', 'processing', 'completed', 'failed', 'cancelled', 'expired'],
    default: 'pending',
    index: true
  },
  amount: {
    type: mongoose.Decimal128,
    required: true,
    get: function(value) {
      return parseFloat(value.toString());
    }
  },
  currency: {
    type: String,
    required: true,
    uppercase: true
  },
  fees: {
    amount: {
      type: mongoose.Decimal128,
      default: 0,
      get: function(value) {
        return parseFloat(value.toString());
      }
    },
    currency: {
      type: String,
      uppercase: true
    },
    breakdown: [{
      type: { type: String }, // 'network', 'service', 'exchange'
      amount: {
        type: mongoose.Decimal128,
        get: function(value) {
          return parseFloat(value.toString());
        }
      },
      currency: String
    }]
  },
  fromAddress: {
    type: String,
    trim: true
  },
  toAddress: {
    type: String,
    trim: true
  },
  description: {
    type: String,
    trim: true,
    maxlength: 500
  },
  reference: {
    type: String,
    trim: true,
    index: true
  },
  exchangeRate: {
    rate: Number,
    fromCurrency: String,
    toCurrency: String,
    timestamp: Date
  },
  blockchain: {
    txHash: {
      type: String,
      sparse: true,
      index: true
    },
    blockHeight: Number,
    confirmations: {
      type: Number,
      default: 0
    },
    requiredConfirmations: {
      type: Number,
      default: 1
    },
    networkFee: {
      type: mongoose.Decimal128,
      get: function(value) {
        return value ? parseFloat(value.toString()) : 0;
      }
    }
  },
  lightning: {
    paymentHash: String,
    invoice: String,
    preimage: String,
    routingFee: {
      type: mongoose.Decimal128,
      get: function(value) {
        return value ? parseFloat(value.toString()) : 0;
      }
    }
  },
  metadata: {
    userAgent: String,
    ipAddress: String,
    deviceId: String,
    location: {
      country: String,
      city: String,
      coordinates: {
        latitude: Number,
        longitude: Number
      }
    },
    bitnobResponse: mongoose.Schema.Types.Mixed,
    retryCount: {
      type: Number,
      default: 0
    },
    lastRetryAt: Date
  },
  completedAt: Date,
  failedAt: Date,
  failureReason: String,
  expiresAt: Date
}, {
  timestamps: true,
  collection: 'transactions',
  toJSON: { getters: true },
  toObject: { getters: true }
});

// Indexes for performance and queries
transactionSchema.index({ userId: 1, createdAt: -1 });
transactionSchema.index({ walletId: 1, createdAt: -1 });
transactionSchema.index({ bitnobTransactionId: 1 });
transactionSchema.index({ status: 1, createdAt: -1 });
transactionSchema.index({ type: 1, status: 1 });
transactionSchema.index({ 'blockchain.txHash': 1 });
transactionSchema.index({ reference: 1 });
transactionSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

// Virtual for net amount (amount - fees)
transactionSchema.virtual('netAmount').get(function() {
  return this.amount - (this.fees.amount || 0);
});

// Virtual for confirmation status
transactionSchema.virtual('isConfirmed').get(function() {
  if (!this.blockchain.confirmations || !this.blockchain.requiredConfirmations) {
    return this.status === 'completed';
  }
  return this.blockchain.confirmations >= this.blockchain.requiredConfirmations;
});

// Pre-save middleware
transactionSchema.pre('save', function(next) {
  // Set completion timestamp
  if (this.isModified('status')) {
    if (this.status === 'completed' && !this.completedAt) {
      this.completedAt = new Date();
    } else if (this.status === 'failed' && !this.failedAt) {
      this.failedAt = new Date();
    }
  }
  
  // Set currency for fees if not provided
  if (this.fees && this.fees.amount > 0 && !this.fees.currency) {
    this.fees.currency = this.currency;
  }
  
  next();
});

// Static method to find user's transactions
transactionSchema.statics.findByUserId = function(userId, options = {}) {
  const query = { userId };
  
  if (options.status) {
    query.status = options.status;
  }
  
  if (options.type) {
    query.type = options.type;
  }
  
  if (options.walletId) {
    query.walletId = options.walletId;
  }
  
  if (options.dateFrom) {
    query.createdAt = { $gte: new Date(options.dateFrom) };
  }
  
  if (options.dateTo) {
    query.createdAt = { ...query.createdAt, $lte: new Date(options.dateTo) };
  }
  
  const limit = parseInt(options.limit) || 20;
  const skip = parseInt(options.skip) || 0;
  
  return this.find(query)
    .sort({ createdAt: -1 })
    .limit(limit)
    .skip(skip)
    .populate('walletId', 'currency label walletType');
};

// Static method to find by Bitnob transaction ID
transactionSchema.statics.findByBitnobId = function(bitnobTransactionId) {
  return this.findOne({ bitnobTransactionId });
};

// Static method to find by blockchain hash
transactionSchema.statics.findByTxHash = function(txHash) {
  return this.findOne({ 'blockchain.txHash': txHash });
};

// Method to update status
transactionSchema.methods.updateStatus = async function(newStatus, metadata = {}) {
  const updates = { 
    status: newStatus,
    ...metadata
  };
  
  if (newStatus === 'completed') {
    updates.completedAt = new Date();
  } else if (newStatus === 'failed') {
    updates.failedAt = new Date();
  }
  
  return this.updateOne(updates);
};

// Method to add blockchain info
transactionSchema.methods.addBlockchainInfo = async function(blockchainData) {
  const updates = {
    'blockchain.txHash': blockchainData.txHash,
    'blockchain.blockHeight': blockchainData.blockHeight,
    'blockchain.confirmations': blockchainData.confirmations || 0,
    'blockchain.networkFee': blockchainData.networkFee || 0
  };
  
  return this.updateOne(updates);
};

// Method to increment confirmations
transactionSchema.methods.incrementConfirmations = async function() {
  return this.updateOne({
    $inc: { 'blockchain.confirmations': 1 }
  });
};

// Method to check if transaction belongs to user
transactionSchema.methods.belongsToUser = function(userId) {
  return this.userId.toString() === userId.toString();
};

// Static method for transaction statistics
transactionSchema.statics.getStats = function(userId, options = {}) {
  const match = { userId };
  
  if (options.dateFrom || options.dateTo) {
    match.createdAt = {};
    if (options.dateFrom) match.createdAt.$gte = new Date(options.dateFrom);
    if (options.dateTo) match.createdAt.$lte = new Date(options.dateTo);
  }
  
  return this.aggregate([
    { $match: match },
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 },
        totalAmount: { $sum: { $toDouble: '$amount' } }
      }
    }
  ]);
};

module.exports = mongoose.model('Transaction', transactionSchema);
