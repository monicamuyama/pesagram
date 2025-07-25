// Simple MongoDB connection test
const mongoose = require('mongoose');
require('dotenv').config();

console.log('🔧 Testing MongoDB Connection...');
console.log('🔧 MongoDB URI:', process.env.MONGODB_URI?.substring(0, 50) + '...');

async function testConnection() {
  try {
    console.log('🔌 Attempting to connect...');
    
    // Set a shorter timeout for testing
    const connection = await mongoose.connect(process.env.MONGODB_URI, {
      serverSelectionTimeoutMS: 15000, // 15 seconds timeout
      maxPoolSize: 1 // Single connection for testing
    });
    
    console.log('✅ Successfully connected to MongoDB Atlas!');
    console.log('✅ Database:', connection.connection.db.databaseName);
    console.log('✅ Host:', connection.connection.host);
    
    // List collections to verify access
    const collections = await connection.connection.db.listCollections().toArray();
    console.log('📁 Available collections:', collections.map(c => c.name));
    
    await mongoose.disconnect();
    console.log('🔌 Disconnected successfully');
    
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
    console.error('❌ Error details:', {
      name: error.name,
      code: error.code,
      codeName: error.codeName
    });
    
    // Check specific error types
    if (error.message.includes('Authentication failed')) {
      console.error('🔑 Issue: Wrong username or password');
    } else if (error.message.includes('IP')) {
      console.error('🌐 Issue: IP not whitelisted');
    } else if (error.message.includes('DNS')) {
      console.error('🌐 Issue: DNS resolution problem');
    }
    
    process.exit(1);
  }
}

testConnection();
