const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  action: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  details: {
    type: String,
    trim: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
}, {
  collection: 'audit_logs'
});

auditLogSchema.index({ userId: 1, createdAt: -1 });

type AuditLogDocument = mongoose.Document & {
  userId: mongoose.Types.ObjectId;
  action: string;
  details?: string;
  createdAt: Date;
};

module.exports = mongoose.model('AuditLog', auditLogSchema); 