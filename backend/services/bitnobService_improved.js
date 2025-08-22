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

  // ===== CUSTOMER MANAGEMENT =====
  async createCustomer(customerData) {
    try {
      const response = await this.client.post('/v1/customers', {
        email: customerData.email,
        firstName: customerData.firstName,
        lastName: customerData.lastName,
        phone: customerData.phone,
        countryCode: customerData.countryCode || '+234' // Default to Nigeria
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Customer creation failed');
    }
  }

  async getCustomer(customerId) {
    try {
      const response = await this.client.get(`/v1/customers/${customerId}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to fetch customer');
    }
  }

  async updateCustomer(customerId, updateData) {
    try {
      const response = await this.client.put(`/v1/customers/${customerId}`, updateData);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Customer update failed');
    }
  }

  // ===== WALLET MANAGEMENT =====
  async getOrganizationWallets() {
    try {
      const response = await this.client.get('/v1/wallets');
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to fetch organization wallets');
    }
  }

  async createCryptoWallet(walletData) {
    try {
      const response = await this.client.post('/v1/wallets/create-new-crypto-wallet', {
        currency: walletData.currency,
        label: walletData.label || `${walletData.currency} Wallet`,
        customer: walletData.customerId
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Crypto wallet creation failed');
    }
  }

  async getCryptoWallet(walletId) {
    try {
      const response = await this.client.get(`/v1/wallets/crypto-wallet/trx/${walletId}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to fetch crypto wallet');
    }
  }

  // ===== BITCOIN OPERATIONS =====
  async generateBitcoinAddress(customerId) {
    try {
      const response = await this.client.post('/v1/addresses/generate', {
        customer: customerId,
        label: `Address for customer ${customerId}`
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Bitcoin address generation failed');
    }
  }

  async sendBitcoin(transactionData) {
    try {
      const response = await this.client.post('/v1/wallets/send_bitcoin', {
        customer: transactionData.customerId,
        address: transactionData.toAddress,
        amount: transactionData.amount,
        description: transactionData.description || 'Bitcoin transfer'
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Bitcoin transfer failed');
    }
  }

  async getBitcoinAddresses(customerId) {
    try {
      const response = await this.client.get(`/v1/addresses?customer=${customerId}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to fetch Bitcoin addresses');
    }
  }

  // ===== LIGHTNING NETWORK =====
  async createLightningInvoice(invoiceData) {
    try {
      const response = await this.client.post('/v1/lnurl/createLnUrlWithdrawal', {
        customer: invoiceData.customerId,
        amount: invoiceData.amount,
        description: invoiceData.description || 'Lightning payment',
        expiry: invoiceData.expiry || 3600 // 1 hour default
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Lightning invoice creation failed');
    }
  }

  async payLightningInvoice(paymentData) {
    try {
      const response = await this.client.post('/v1/lnurl/receiveLnUrlWithdrawal', {
        customer: paymentData.customerId,
        invoice: paymentData.invoice
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Lightning payment failed');
    }
  }

  // ===== TRANSACTIONS =====
  async getTransactions(params = {}) {
    try {
      const queryString = new URLSearchParams({
        page: params.page || 1,
        limit: params.limit || 20,
        ...(params.customer && { customer: params.customer }),
        ...(params.status && { status: params.status }),
        ...(params.type && { type: params.type })
      }).toString();
      
      const response = await this.client.get(`/v1/transactions?${queryString}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to fetch transactions');
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

  // ===== EXCHANGE RATES =====
  async getAllExchangeRates() {
    try {
      const response = await this.client.get('/v1/wallets/payout/rates');
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'Failed to fetch exchange rates');
    }
  }

  async getExchangeRateByCurrency(currency) {
    try {
      const response = await this.client.get(`/v1/wallets/payout/rate/${currency}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error, `Failed to fetch exchange rate for ${currency}`);
    }
  }

  // ===== WALLET SWAPS =====
  async initializeUSDToBTCSwap(swapData) {
    try {
      const response = await this.client.post('/v1/api/wallets/initialize-swap-for-bitcoin', {
        customer: swapData.customerId,
        amount: swapData.amount
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'USD to BTC swap initialization failed');
    }
  }

  async finalizeUSDToBTCSwap(swapId) {
    try {
      const response = await this.client.post(`/v1/wallets/finalize-swap-for-bitcoin/${swapId}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'USD to BTC swap finalization failed');
    }
  }


  // ===== BTC to USB =====
  
  async initializeBTCToUSDSwap(swapData) {
    try {
      const response = await this.client.post('/v1/api/wallets/initialize-swap-for-usd', {
        customer: swapData.customerId,
        amount: swapData.amount
      });
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'BTC to USD swap initialization failed');
    }
  }

  
  async finalizeBTCToUSDSwap(swapId) {
    try {
      const response = await this.client.post(`/v1/wallets/finalize-swap-for-usd/${swapId}`);
      return response.data;
    } catch (error) {
      throw this.handleError(error, 'BTC to USD swap finalization failed');
    }
  }
  // ===== ERROR HANDLING =====
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
