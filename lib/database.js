const mongoose = require('mongoose');

// Connection management for serverless environment
let cachedConnection = null;

const connectToDatabase = async () => {
  if (cachedConnection) {
    console.log('📚 Using cached database connection');
    return cachedConnection;
  }

  try {
    const mongoUri = process.env.MONGODB_URI;
    const dbName = process.env.MONGODB_DB_NAME || 'pesagram-prod';

    if (!mongoUri) {
      throw new Error('MONGODB_URI environment variable is not defined');
    }

    console.log('🔌 Connecting to MongoDB Atlas...');

    // Optimized for serverless - reuse connections
    const connection = await mongoose.connect(mongoUri, {
      dbName,
      bufferCommands: false,
      serverSelectionTimeoutMS: 5000, // Timeout after 5s instead of 30s
      socketTimeoutMS: 45000,
      maxPoolSize: 10, // Maintain up to 10 socket connections
      minPoolSize: 1,  // Maintain at least 1 socket connection
      maxIdleTimeMS: 30000, // Close connections after 30 seconds of inactivity
    });

    cachedConnection = connection;
    console.log('✅ Connected to MongoDB Atlas successfully');
    
    return connection;
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    throw error;
  }
};

// Graceful disconnect (for local development)
const disconnectFromDatabase = async () => {
  if (cachedConnection) {
    await mongoose.disconnect();
    cachedConnection = null;
    console.log('🔌 Disconnected from MongoDB');
  }
};

// Handle connection events
mongoose.connection.on('connected', () => {
  console.log('🔗 Mongoose connected to MongoDB Atlas');
});

mongoose.connection.on('error', (err) => {
  console.error('❌ Mongoose connection error:', err);
});

mongoose.connection.on('disconnected', () => {
  console.log('🔌 Mongoose disconnected from MongoDB');
});

// For serverless environments, we don't want to keep connections open
process.on('SIGINT', async () => {
  await disconnectFromDatabase();
  process.exit(0);
});

module.exports = {
  connectToDatabase,
  disconnectFromDatabase
};
