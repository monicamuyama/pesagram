# 🚀 MongoDB Atlas + Vercel Deployment Checklist

## ✅ Pre-Deployment Setup

### 1. MongoDB Atlas Setup
- [ ] Create MongoDB Atlas account
- [ ] Create new cluster (M0 free tier)
- [ ] Create database user with strong password
- [ ] Whitelist IP: `0.0.0.0/0` (for Vercel serverless functions)
- [ ] Create database: `monikhangu-prod`
- [ ] Get connection string
- [ ] Test connection locally

### 2. Vercel Account Setup
- [ ] Create Vercel account
- [ ] Connect GitHub repository
- [ ] Install Vercel CLI: `npm install -g vercel`

### 3. Environment Variables Setup
- [ ] Copy `.env.production` variables to Vercel dashboard
- [ ] Generate secure JWT_SECRET (32+ characters)
- [ ] Generate BITNOB_WEBHOOK_SECRET
- [ ] Set production BITNOB_API_KEY

## 🛠️ Deployment Steps

### Step 1: Update Dependencies
```bash
cd backend
npm install mongoose
npm install @vercel/node --save-dev
```

### Step 2: Test Locally with MongoDB Atlas
```bash
# Create .env.local with MongoDB Atlas connection
cp .env.production .env.local
# Update MONGODB_URI with your actual connection string
npm run dev
```

### Step 3: Deploy to Vercel
```bash
# Login to Vercel
vercel login

# Deploy
vercel --prod

# Or link to existing project
vercel link
vercel --prod
```

### Step 4: Configure Environment Variables in Vercel
1. Go to Vercel Dashboard → Your Project → Settings → Environment Variables
2. Add all variables from `.env.production`
3. Mark sensitive variables as "Encrypted"

**Required Variables:**
- `MONGODB_URI`
- `MONGODB_DB_NAME`
- `JWT_SECRET`
- `BITNOB_API_KEY`
- `BITNOB_BASE_URL`
- `BITNOB_WEBHOOK_SECRET`
- `ALLOWED_ORIGINS`

### Step 5: Test API Endpoints
```bash
# Test health endpoint
curl https://your-app.vercel.app/api/health

# Test signup
curl -X POST https://your-app.vercel.app/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"SecurePass123!","firstName":"Test","lastName":"User","phone":"+1234567890"}'
```

## 📱 Update Flutter App

### Update API Base URL
```dart
// lib/config/config.dart
class Config {
  static const String baseUrl = 'https://your-app.vercel.app/api';
  static const String environment = 'production';
}
```

### Update BitnobService
```dart
// lib/services/bitnob_service.dart
class BitnobService {
  static const String baseUrl = 'https://your-app.vercel.app/api';
  // ... rest of the service
}
```

## 🔒 Security Checklist

### Database Security
- [ ] Strong database password (20+ characters)
- [ ] Enable MongoDB Atlas encryption at rest
- [ ] Set up database backups
- [ ] Monitor database access logs

### API Security
- [ ] HTTPS only (Vercel provides SSL automatically)
- [ ] Strong JWT secret (32+ characters)
- [ ] Rate limiting configured
- [ ] Input validation on all endpoints
- [ ] CORS properly configured

### Bitnob Security
- [ ] Production API key secured
- [ ] Webhook secret configured
- [ ] IP whitelisting (if supported)
- [ ] Monitor API usage

## 📊 Monitoring Setup

### Vercel Analytics
- [ ] Enable function analytics in Vercel dashboard
- [ ] Set up error tracking
- [ ] Monitor function execution times

### MongoDB Atlas Monitoring
- [ ] Enable performance advisor
- [ ] Set up alerts for high CPU/memory usage
- [ ] Monitor slow queries

### Error Tracking (Optional)
```bash
# Add Sentry for error tracking
npm install @sentry/node
```

## 🧪 Testing Checklist

### API Testing
- [ ] User registration works
- [ ] User login works
- [ ] JWT token validation works
- [ ] Wallet creation works
- [ ] Database connection stable
- [ ] Error handling works

### Performance Testing
- [ ] API response times < 500ms
- [ ] Database queries optimized
- [ ] Function cold start times acceptable
- [ ] No memory leaks

## 🚨 Common Issues & Solutions

### Issue: "Cannot connect to MongoDB"
**Solution:**
- Check MONGODB_URI format
- Verify IP whitelist includes `0.0.0.0/0`
- Ensure database user has correct permissions

### Issue: "Function timeout"
**Solution:**
- Optimize database queries
- Add connection pooling
- Reduce function complexity
- Consider caching

### Issue: "CORS errors"
**Solution:**
- Update ALLOWED_ORIGINS environment variable
- Check CORS headers in API responses
- Verify frontend domain is correct

### Issue: "JWT token invalid"
**Solution:**
- Verify JWT_SECRET is same across deployments
- Check token expiration time
- Ensure proper token format in headers

## 📈 Scaling Considerations

### Database Scaling
- Start with M0 (free tier)
- Upgrade to M10 ($57/month) when needed
- Enable auto-scaling for production

### API Scaling
- Vercel auto-scales based on requests
- Monitor function execution limits
- Consider upgrading to Pro plan ($20/month)

### Cost Optimization
- Use MongoDB connection pooling
- Implement caching for frequently accessed data
- Optimize database indexes
- Monitor and optimize function execution times

## 🎯 Post-Deployment Tasks

### Documentation
- [ ] Update API documentation
- [ ] Create user guides
- [ ] Document deployment process

### Monitoring
- [ ] Set up health checks
- [ ] Create monitoring dashboards
- [ ] Set up alerting

### Backup & Recovery
- [ ] Verify MongoDB backups
- [ ] Test recovery procedures
- [ ] Document disaster recovery plan

---

**Next Steps After Deployment:**
1. Monitor application performance for 24-48 hours
2. Test all critical user flows
3. Set up production monitoring and alerting
4. Plan for scaling based on user growth
5. Regular security audits and updates
