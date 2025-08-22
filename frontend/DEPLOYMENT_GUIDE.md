# 🌐 Monikhangu - Cloud Deployment Guide (MongoDB Atlas + Vercel)

## 🚀 Deployment Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  Vercel Backend │    │ MongoDB Atlas   │
│  (Mobile/Web)   │ ── │  (Serverless)   │ ── │   (Database)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
    ┌─────────┐            ┌──────────┐            ┌──────────┐
    │ Users   │            │ Bitnob   │            │ Secure   │
    │ Global  │            │ API      │            │ Cluster  │
    │ Access  │            │ Integration │         │ Global   │
    └─────────┘            └──────────┘            └──────────┘
```

## 📋 Pre-Deployment Checklist

### 1. **MongoDB Atlas Setup**
- [x] Create MongoDB Atlas account
- [x] Set up free cluster (M0)
- [x] Configure database user
- [x] Whitelist IP addresses
- [x] Get connection string

### 2. **Vercel Setup**
- [x] Create Vercel account
- [x] Install Vercel CLI
- [x] Configure environment variables
- [x] Set up serverless functions

### 3. **Code Modifications**
- [x] Update database connection
- [x] Modify for serverless architecture
- [x] Environment variable configuration
- [x] CORS setup for production

## 🛠️ Step-by-Step Implementation

### Step 1: MongoDB Atlas Configuration

1. **Create Atlas Account**: Visit [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. **Create Free Cluster**: 
   - Choose AWS/Google Cloud/Azure
   - Select region closest to your users
   - Use M0 (Free tier) for testing

3. **Database Setup**:
   ```
   Database Name: monikhangu-prod
   Collections:
   - users
   - wallets
   - transactions
   - bitcoin_addresses
   - sessions
   ```

4. **Security Configuration**:
   - Create database user with strong password
   - Whitelist IP: `0.0.0.0/0` (for Vercel serverless)
   - Enable authentication

### Step 2: Vercel Deployment Setup

1. **Install Vercel CLI**:
   ```bash
   npm install -g vercel
   vercel login
   ```

2. **Project Structure for Vercel**:
   ```
   backend/
   ├── api/                 # Vercel serverless functions
   │   ├── auth/
   │   │   ├── signup.js
   │   │   ├── signin.js
   │   │   └── verify.js
   │   ├── wallet/
   │   │   ├── index.js
   │   │   └── [id].js
   │   ├── transaction/
   │   └── webhooks/
   ├── lib/                 # Shared utilities
   │   ├── database.js
   │   ├── bitnob.js
   │   └── auth.js
   ├── models/              # MongoDB models
   ├── middleware/
   ├── vercel.json         # Vercel configuration
   └── package.json
   ```

## 🔧 Environment Variables (Production)

### MongoDB Atlas:
```env
MONGODB_URI=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/monikhangu-prod?retryWrites=true&w=majority
MONGODB_DB_NAME=monikhangu-prod
```

### Bitnob Production:
```env
BITNOB_BASE_URL=https://api.bitnob.co/api
BITNOB_API_KEY=your_production_api_key
BITNOB_ENVIRONMENT=production
BITNOB_WEBHOOK_SECRET=your_webhook_secret
```

### Application:
```env
NODE_ENV=production
JWT_SECRET=your_production_jwt_secret_minimum_32_characters
BCRYPT_ROUNDS=12
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

## 📊 Cost Analysis

### Free Tier Limits:
- **MongoDB Atlas M0**: 512MB storage, shared CPU
- **Vercel Hobby**: 100GB bandwidth, 100 serverless functions
- **Total Monthly Cost**: $0 for moderate usage

### Scaling Costs:
- **MongoDB Atlas M10**: ~$57/month (2GB RAM, 10GB storage)
- **Vercel Pro**: $20/month (1TB bandwidth, advanced features)
- **Estimated Monthly**: $77 for production-ready setup

## 🔒 Security Considerations

### Database Security:
- Enable MongoDB Atlas encryption at rest
- Use strong database passwords
- Implement IP whitelisting when possible
- Regular backup strategy

### API Security:
- HTTPS only (Vercel provides SSL automatically)
- JWT token validation
- Rate limiting per IP/user
- Input validation and sanitization

### Compliance:
- GDPR compliance for EU users
- Data retention policies
- Audit logging for financial transactions
- PCI DSS considerations for payment data

## 📈 Performance Optimization

### Database:
- Index frequently queried fields
- Use aggregation pipelines efficiently
- Implement caching with Redis (if needed)
- Connection pooling

### API:
- Optimize serverless function cold starts
- Implement proper caching headers
- Use edge functions for static data
- Minimize bundle sizes

## 🚨 Important Notes

### Serverless Limitations:
- 10-second execution limit on Vercel
- Stateless functions (no persistent connections)
- Cold start latency
- Memory limits (1GB max on Pro plan)

### Solutions:
- Use connection pooling for database
- Implement proper error handling
- Cache frequently accessed data
- Use background jobs for long-running tasks

## 📱 Flutter App Updates

### Production API Endpoint:
```dart
class Config {
  static const String baseUrl = 'https://your-vercel-app.vercel.app/api';
  static const String environment = 'production';
}
```

### Error Handling:
```dart
class ApiService {
  static Future<Map<String, dynamic>> makeRequest(String endpoint, {
    Map<String, dynamic>? data,
    String method = 'GET',
  }) async {
    try {
      // Implement retry logic
      // Handle network errors
      // Cache responses when appropriate
    } catch (e) {
      // Proper error handling
    }
  }
}
```

## 🔄 CI/CD Pipeline

### Automated Deployment:
1. **GitHub Integration**: Connect repo to Vercel
2. **Auto Deploy**: Every push to main branch
3. **Environment Variables**: Set in Vercel dashboard
4. **Testing**: Automated tests before deployment

### Deployment Checklist:
- [ ] Environment variables configured
- [ ] Database connected and tested
- [ ] API endpoints responding
- [ ] Webhooks configured
- [ ] SSL certificate active
- [ ] Custom domain setup (optional)

## 📞 Support & Monitoring

### Vercel Analytics:
- Function execution logs
- Performance metrics
- Error tracking
- Usage analytics

### MongoDB Atlas Monitoring:
- Database performance
- Query optimization suggestions
- Security alerts
- Backup status

---

**Next Steps**: Follow the implementation files I'm creating to set up your MongoDB Atlas + Vercel deployment.
