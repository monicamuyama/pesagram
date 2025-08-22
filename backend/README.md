# Monikhangu Backend API

A Node.js Express backend API server for the Monikhangu mobile application, providing secure integration with the Bitnob Sandbox API for cryptocurrency and fiat financial services.

## 🚀 Features

- **Authentication & Authorization**: JWT-based authentication with secure password hashing
- **Wallet Management**: Create and manage multiple cryptocurrency and fiat wallets
- **Transaction Processing**: Send money, currency swaps, and transaction history
- **Real-time Exchange Rates**: Live cryptocurrency and fiat currency conversion rates
- **Security**: Rate limiting, CORS protection, input validation, and security headers
- **API Documentation**: RESTful API with comprehensive error handling
- **Bitnob Integration**: Seamless integration with Bitnob Sandbox API

## 📋 Prerequisites

- Node.js (>= 16.0.0)
- npm or yarn
- Bitnob Sandbox API Key

## 🛠️ Installation

1. **Clone and navigate to backend directory**:
   ```bash
   cd backend
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Environment Setup**:
   ```bash
   cp .env.example .env
   ```

4. **Configure environment variables** in `.env`:
   ```env
   NODE_ENV=development
   PORT=3000
   
   # Bitnob Sandbox API
   BITNOB_BASE_URL=https://sandboxapi.bitnob.co
   BITNOB_API_KEY=your_bitnob_sandbox_api_key_here
   
   # JWT Configuration
   JWT_SECRET=your_super_secure_jwt_secret_key
   JWT_EXPIRES_IN=24h
   
   # Security
   BCRYPT_ROUNDS=12
   ```

5. **Start the server**:
   ```bash
   # Development mode with auto-reload
   npm run dev
   
   # Production mode
   npm start
   ```

## 📚 API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `GET /api/auth/verify` - Verify JWT token

### Wallet Management
- `GET /api/wallet` - Get user wallets
- `POST /api/wallet` - Create new wallet
- `GET /api/wallet/:walletId/balance` - Get wallet balance
- `GET /api/wallet/rates` - Get exchange rates

### Transactions
- `GET /api/transaction` - Get transaction history
- `GET /api/transaction/:transactionId` - Get transaction details
- `POST /api/transaction/send` - Send money
- `POST /api/transaction/swap` - Currency swap

### User Management
- `GET /api/user/profile` - Get user profile
- `PUT /api/user/profile` - Update user profile
- `GET /api/user/settings` - Get user settings
- `PUT /api/user/settings` - Update user settings

### System
- `GET /health` - Health check endpoint

## 🔧 API Request Examples

### Register User
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securepassword123",
    "firstName": "John",
    "lastName": "Doe",
    "phone": "+1234567890"
  }'
```

### Login User
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securepassword123"
  }'
```

### Get Wallets (Authenticated)
```bash
curl -X GET http://localhost:3000/api/wallet \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Send Money (Authenticated)
```bash
curl -X POST http://localhost:3000/api/transaction/send \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "fromWalletId": "wallet_123",
    "toAddress": "recipient_address",
    "amount": 100.50,
    "currency": "USD",
    "description": "Payment for services"
  }'
```

## 🏗️ Project Structure

```
backend/
├── middleware/
│   ├── auth.js           # JWT authentication middleware
│   └── errorHandler.js   # Global error handling
├── routes/
│   ├── auth.js          # Authentication routes
│   ├── wallet.js        # Wallet management routes
│   ├── transaction.js   # Transaction routes
│   └── user.js          # User management routes
├── services/
│   └── bitnobService.js # Bitnob API integration
├── .env.example         # Environment variables template
├── .gitignore          # Git ignore rules
├── server.js           # Main server file
└── package.json        # Dependencies and scripts
```

## 🔒 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Password Hashing**: bcrypt with configurable rounds
- **Rate Limiting**: Prevent API abuse
- **CORS Protection**: Configurable cross-origin requests
- **Input Validation**: Comprehensive request validation
- **Security Headers**: Helmet.js security headers
- **Environment Variables**: Secure configuration management

## 🧪 Testing

```bash
# Run tests
npm test

# Run tests with coverage
npm run test:coverage
```

## 🚀 Deployment

1. **Production Environment**:
   ```bash
   NODE_ENV=production
   ```

2. **Environment Variables**: Set all required environment variables

3. **Process Manager** (PM2 recommended):
   ```bash
   npm install -g pm2
   pm2 start server.js --name "monikhangu-api"
   ```

## 📊 Monitoring

- Health check endpoint: `GET /health`
- Server logs with Morgan middleware
- Error tracking with comprehensive error handling

## 🤝 Integration with Flutter App

Update your Flutter app's `BitnobService` to point to this backend:

```dart
static const String baseUrl = 'http://your-backend-url:3000/api';
```

## 📞 Support

For issues related to:
- **Bitnob API**: Check [Bitnob Documentation](https://docs.bitnob.com)
- **Backend Issues**: Check server logs and error responses
- **Authentication**: Verify JWT token and API endpoints

## 🔄 Version

Current Version: 1.0.0

---

Built with ❤️ for secure financial transactions
