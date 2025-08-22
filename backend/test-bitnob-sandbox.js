// Bitnob Sandbox API Test
require('dotenv').config();
const axios = require('axios');

async function testBitnobSandbox() {
  console.log('🧪 Testing Bitnob Sandbox API...');
  console.log('🔧 Base URL:', process.env.BITNOB_BASE_URL);
  console.log('🔑 API Key:', process.env.BITNOB_API_KEY?.substring(0, 10) + '...');

  const client = axios.create({
    baseURL: process.env.BITNOB_BASE_URL,
    timeout: 10000,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${process.env.BITNOB_API_KEY}`
    }
  });

  try {
    // Test 1: Check API health/status
    console.log('\n📡 Test 1: API Health Check...');
    const healthResponse = await client.get('/api/v1/health');
    console.log('✅ Health Check:', healthResponse.status, healthResponse.data);
  } catch (error) {
    console.log('❌ Health check failed:', error.response?.status, error.response?.data || error.message);
  }

  try {
    // Test 2: Get supported currencies
    console.log('\n💰 Test 2: Get Supported Currencies...');
    const currenciesResponse = await client.get('/api/v1/currencies');
    console.log('✅ Currencies:', currenciesResponse.status);
    console.log('📋 Available currencies:', currenciesResponse.data?.data?.slice(0, 5)); // Show first 5
  } catch (error) {
    console.log('❌ Currencies failed:', error.response?.status, error.response?.data || error.message);
  }

  try {
    // Test 3: Create a test customer
    console.log('\n👤 Test 3: Create Test Customer...');
    const customerData = {
      email: `test-${Date.now()}@example.com`,
      firstName: 'Test',
      lastName: 'User',
      phone: '+256700000000'
    };
    
    const customerResponse = await client.post('/api/v1/customers', customerData);
    console.log('✅ Customer created:', customerResponse.status);
    console.log('👤 Customer ID:', customerResponse.data?.data?.id);
  } catch (error) {
    console.log('❌ Customer creation failed:', error.response?.status);
    console.log('📋 Error details:', error.response?.data);
  }

  try {
    // Test 4: Get exchange rates
    console.log('\n💱 Test 4: Get Exchange Rates...');
    const ratesResponse = await client.get('/api/v1/rates');
    console.log('✅ Rates:', ratesResponse.status);
    console.log('💱 Sample rates:', Object.keys(ratesResponse.data?.data || {}).slice(0, 3));
  } catch (error) {
    console.log('❌ Rates failed:', error.response?.status, error.response?.data || error.message);
  }

  console.log('\n🏁 Bitnob sandbox test completed!');
}

testBitnobSandbox().catch(console.error);
