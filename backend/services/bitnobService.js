const axios = require('axios');

class BitnobAPIService {
  constructor() {
    this.baseURL = process.env.BITNOB_BASE_URL;
    this.apiKey = process.env.BITNOB_API_KEY;
    
    if (!this.baseURL || !this.apiKey) {
      throw new Error('Bitnob API configuration missing. Check BITNOB_BASE_URL and BITNOB_API_KEY environment variables.');
    }

    this.client = axios.create({
      baseURL: this.baseURL,
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`
      }
    });

    // Request interceptor for logging
    this.client.interceptors.request.use(
      (config) => {
        console.log(`📤 Bitnob API Request: ${config.method?.toUpperCase()} ${config.url}`);
        if (config.data && process.env.NODE_ENV !== 'production') {
          console.log('Request data:', JSON.stringify(config.data, null, 2));
        }
        return config;
      },
      (error) => {
        console.error('📤 Request interceptor error:', error);
        return Promise.reject(error);
      }
    );

    // Response interceptor for logging
    this.client.interceptors.response.use(
      (response) => {
        console.log(`📥 Bitnob API Response: ${response.status} ${response.config.url}`);
        return response;
      },
      (error) => {
        console.error('📥 Bitnob API Error:', {
          url: error.config?.url,
          status: error.response?.status,
          message: error.response?.data?.message || error.message
        });
        return Promise.reject(error);
      }
    );
  }

  // Authentication endpoints
  async createUser(userData) {
    try {
      const response = await this.client.post('/v1/customers', userData);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'User creation failed');
    }
  }

  // Note: Bitnob doesn't provide authentication - handle login locally
  // The createUser method above creates a customer record for wallet management

  // Wallet endpoints
  async getWallets(userId) {
    try {
      const response = await this.client.get(`/v1/wallets?userId=${userId}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to fetch wallets');
    }
  }

  async createWallet(walletData) {
    try {
      const response = await this.client.post('/v1/wallets', walletData);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Wallet creation failed');
    }
  }

  async getWalletBalance(walletId) {
    try {
      const response = await this.client.get(`/v1/wallets/${walletId}/balance`);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to fetch wallet balance');
    }
  }

  // Transaction endpoints
  async sendMoney(transactionData) {
    try {
      const response = await this.client.post('/v1/transactions/send', transactionData);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Money transfer failed');
    }
  }

  async getTransactionHistory(walletId, params = {}) {
    try {
      const queryString = new URLSearchParams(params).toString();
      const url = `/v1/transactions?walletId=${walletId}${queryString ? '&' + queryString : ''}`;
      const response = await this.client.get(url);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to fetch transaction history');
    }
  }

  async getTransaction(transactionId) {
    try {
      const response = await this.client.get(`/v1/transactions/${transactionId}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to fetch transaction details');
    }
  }

  // Currency conversion endpoints
  async getExchangeRates(baseCurrency = 'USD') {
    try {
      const response = await this.client.get(`/v1/rates?base=${baseCurrency}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to fetch exchange rates');
    }
  }

  async swapCurrency(swapData) {
    try {
      const response = await this.client.post('/v1/transactions/swap', swapData);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Currency swap failed');
    }
  }

  // KYC submission endpoint (pseudo, adapt to Bitnob API)
  async submitKYC(kycPayload) {
    try {
      // Replace with actual Bitnob endpoint and payload structure
      const response = await this.client.post('/v1/kyc/submit', kycPayload);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'KYC submission failed');
    }
  }

  // Error handler
  handleError(error, defaultMessage) {
    if (error.response) {
      // API responded with error status
      const apiError = new Error(error.response.data?.message || defaultMessage);
      apiError.status = error.response.status;
      apiError.data = error.response.data;
      return apiError;
    } else if (error.request) {
      // Request was made but no response
      const networkError = new Error('Network error: Unable to reach Bitnob API');
      networkError.status = 503;
      return networkError;
    } else {
      // Something else happened
      const generalError = new Error(defaultMessage);
      generalError.status = 500;
      return generalError;
    }
  }
}

module.exports = new BitnobAPIService();
