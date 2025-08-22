const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

// Import database connection
const { connectToDatabase } = require('./lib/database');

// Import routes
const authRoutes = require('./routes/auth');
const walletRoutes = require('./routes/wallet');
const transactionRoutes = require('./routes/transaction');
const userRoutes = require('./routes/user');
const kycRoutes = require('./routes/kyc');
const mobileMoneyRoutes = require('./routes/mobileMoney');
const recurringPaymentsRoutes = require('./routes/recurringPayments');

// Import middleware
const errorHandler = require('./middleware/errorHandler');
const { authenticateToken } = require('./middleware/auth');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(compression());

// CORS configuration
const corsOptions = {
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true,
  optionsSuccessStatus: 200
};
app.use(cors(corsOptions));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    error: 'Too many requests from this IP, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false
});
app.use('/api', limiter);

// Logging middleware
if (process.env.NODE_ENV !== 'production') {
  app.use(morgan('dev'));
}

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/wallet', authenticateToken, walletRoutes);
app.use('/api/transaction', authenticateToken, transactionRoutes);
app.use('/api/user', authenticateToken, userRoutes);
app.use('/api/kyc', authenticateToken, kycRoutes);
app.use('/api/mobile-money', authenticateToken, mobileMoneyRoutes);
app.use('/api/recurring-payments', authenticateToken, recurringPaymentsRoutes);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    message: `Cannot ${req.method} ${req.baseUrl}`
  });
});

// Global error handler
app.use(errorHandler);

// Start server
const startServer = async () => {
  try {
    // Try to connect to database, but don't fail if it doesn't work
    try {
      await connectToDatabase();
      console.log(`🗄️ Database: Connected to MongoDB Atlas`);
    } catch (dbError) {
      console.warn('⚠️ Database connection failed, starting server without DB:', dbError.message);
      console.log('🔧 Server will start in offline mode for testing');
    }
    
    const server = app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 Pesagram Backend Server running on port ${PORT}`);
      console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🌐 Health check: http://localhost:${PORT}/health`);
      console.log(`� Ready for mobile app testing at: http://192.168.1.154:${PORT}/api`);
      console.log(`🔗 Server accessible from all network interfaces`);
    });

    // Graceful shutdown
    process.on('SIGTERM', () => {
      console.log('SIGTERM received, shutting down gracefully');
      server.close(() => {
        console.log('Process terminated');
      });
    });

    return server;
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

// Start the server
startServer();

module.exports = app;
