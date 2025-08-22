const mongoose = require('mongoose');

const walletSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  bitnobWalletId: {
    type: String,
    sparse: true,
    index: true
  },
  currency: {
    type: String,
    required: true,
    uppercase: true,
    enum: ['BTC', 'USD', 'NGN', 'EUR', 'GBP', 'CAD', 'KES', 'GHS', 'ZAR']
  },
  walletType: {
    type: String,
    required: true,
    enum: ['bitcoin', 'lightning', 'stablecoin', 'fiat'],
    default: 'bitcoin'
  },
  label: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  balance: {
    type: mongoose.Decimal128,
    default: 0,
    get: function(value) {
      return parseFloat(value.toString());
    }
  },
  availableBalance: {
    type: mongoose.Decimal128,
    default: 0,
    get: function(value) {
      return parseFloat(value.toString());
    }
  },
  pendingBalance: {
    type: mongoose.Decimal128,
    default: 0,
    get: function(value) {
      return parseFloat(value.toString());
    }
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isDefault: {
    type: Boolean,
    default: false
  },
  lastSyncAt: {
    type: Date,
    default: Date.now
  },
  metadata: {
    createdVia: {
      type: String,
      enum: ['app', 'api', 'bitnob'],
      default: 'app'
    },
    lastTransactionAt: {
      type: Date
    },
    transactionCount: {
      type: Number,
      default: 0
    }
  }
}, {
  timestamps: true,
  collection: 'wallets',
  toJSON: { getters: true },
  toObject: { getters: true }
});

// Indexes for performance
walletSchema.index({ userId: 1, currency: 1 });
walletSchema.index({ bitnobWalletId: 1 });
walletSchema.index({ userId: 1, isActive: 1 });
walletSchema.index({ userId: 1, isDefault: 1 });
walletSchema.index({ createdAt: -1 });

// Ensure only one default wallet per currency per user
walletSchema.index(
  { userId: 1, currency: 1, isDefault: 1 },
  { 
    unique: true,
    partialFilterExpression: { isDefault: true }
  }
);

// Pre-save middleware to handle default wallet logic
walletSchema.pre('save', async function(next) {
  if (this.isModified('isDefault') && this.isDefault) {
    // Unset other default wallets of the same currency for this user
    await this.constructor.updateMany(
      { 
        userId: this.userId, 
        currency: this.currency, 
        _id: { $ne: this._id } 
      },
      { $set: { isDefault: false } }
    );
  }
  next();
});

// Static method to find user's wallets
walletSchema.statics.findByUserId = function(userId, options = {}) {
  const query = { userId, isActive: true };
  
  if (options.currency) {
    query.currency = options.currency.toUpperCase();
  }
  
  return this.find(query).sort({ isDefault: -1, createdAt: -1 });
};

// Static method to find wallet by Bitnob ID
walletSchema.statics.findByBitnobId = function(bitnobWalletId) {
  return this.findOne({ bitnobWalletId, isActive: true });
};

// Static method to get user's default wallet for currency
walletSchema.statics.findDefaultWallet = function(userId, currency) {
  return this.findOne({
    userId,
    currency: currency.toUpperCase(),
    isDefault: true,
    isActive: true
  });
};

// Method to update balance
walletSchema.methods.updateBalance = async function(newBalance, type = 'available') {
  const updates = { lastSyncAt: new Date() };
  
  if (type === 'available') {
    updates.availableBalance = newBalance;
  } else if (type === 'total') {
    updates.balance = newBalance;
  } else if (type === 'pending') {
    updates.pendingBalance = newBalance;
  }
  
  return this.updateOne(updates);
};

// Method to increment transaction count
walletSchema.methods.incrementTransactionCount = async function() {
  return this.updateOne({
    $inc: { 'metadata.transactionCount': 1 },
    $set: { 'metadata.lastTransactionAt': new Date() }
  });
};

// Virtual for total balance calculation
walletSchema.virtual('totalBalance').get(function() {
  return this.availableBalance + this.pendingBalance;
});

// Method to check if wallet belongs to user
walletSchema.methods.belongsToUser = function(userId) {
  return this.userId.toString() === userId.toString();
};

module.exports = mongoose.model('Wallet', walletSchema);
