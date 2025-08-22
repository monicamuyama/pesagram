# Pesagram - Repository Separation Guide

## 🚀 Recommended: Split into Two Repositories

### **Repository 1: `pesagram-backend`**
```
pesagram-backend/
├── .github/workflows/
│   └── deploy.yml          # Vercel deployment only
├── api/                    # Vercel serverless functions
├── lib/                    # Database utilities
├── models/                 # MongoDB models
├── middleware/             # Auth, validation
├── services/               # Bitnob integration
├── package.json
├── vercel.json
├── .env.example
└── README.md
```

### **Repository 2: `pesagram-mobile`**
```
pesagram-mobile/
├── .github/workflows/
│   ├── flutter-ci.yml      # Build APK/iOS
│   └── deploy-web.yml      # GitHub Pages
├── lib/                    # Flutter app code
├── android/                # Android config
├── ios/                    # iOS config
├── web/                    # Web config
├── pubspec.yaml
└── README.md
```

## 🔧 Migration Steps

### **Step 1: Create Backend Repository**
```bash
# Create new repo for backend
mkdir pesagram-backend
cd pesagram-backend
git init

# Copy backend files
cp -r ../monikhangu/backend/* .
cp ../monikhangu/.github/workflows/deploy-backend.yml .github/workflows/deploy.yml

# Initialize git
git add .
git commit -m "Initial backend setup"
git remote add origin https://github.com/yourusername/pesagram-backend.git
git push -u origin main
```

### **Step 2: Create Frontend Repository**
```bash
# Create new repo for mobile app
mkdir pesagram-mobile
cd pesagram-mobile
git init

# Copy Flutter files (exclude backend)
cp -r ../monikhangu/lib .
cp -r ../monikhangu/android .
cp -r ../monikhangu/ios .
cp -r ../monikhangu/web .
cp ../monikhangu/pubspec.yaml .
cp ../monikhangu/.github/workflows/flutter-ci.yml .github/workflows/
cp ../monikhangu/.github/workflows/deploy-web.yml .github/workflows/

# Initialize git
git add .
git commit -m "Initial mobile app setup"
git remote add origin https://github.com/yourusername/pesagram-mobile.git
git push -u origin main
```

## 📦 Deployment Benefits

### **Backend (Vercel)**
- ✅ Independent backend deployments
- ✅ API versioning control
- ✅ Database migrations separate from app
- ✅ Environment variables isolated
- ✅ Faster CI/CD (only backend changes)

### **Frontend (Multiple Platforms)**
- ✅ Mobile app store deployments
- ✅ Web app on GitHub Pages/Netlify
- ✅ Independent Flutter upgrades
- ✅ Platform-specific configurations
- ✅ Faster build times

## 🔗 API Configuration

### **Backend URL Configuration:**
```javascript
// In Flutter app - lib/services/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://pesagram-api.vercel.app';
  // For development: 'http://localhost:3000'
}
```

### **CORS Configuration:**
```javascript
// In backend - Update CORS for mobile app
const allowedOrigins = [
  'https://yourusername.github.io',  // Web app
  'capacitor://localhost',           // Mobile app
  'ionic://localhost',
  'http://localhost:*'               // Development
];
```

## 🚀 Alternative: Monorepo with Separate Workflows

If you prefer keeping everything in one repository:

```
pesagram-monorepo/
├── .github/workflows/
│   ├── backend-deploy.yml    # Only triggers on backend/**
│   ├── mobile-ci.yml         # Only triggers on mobile/**
│   └── web-deploy.yml        # Only triggers on mobile/**
├── backend/                  # API code
├── mobile/                   # Flutter app
├── docs/                     # Documentation
└── README.md
```

### **Path-based Workflow Triggers:**
```yaml
# .github/workflows/backend-deploy.yml
on:
  push:
    branches: [main]
    paths: ['backend/**']

# .github/workflows/mobile-ci.yml  
on:
  push:
    branches: [main]
    paths: ['mobile/**']
```

## 💡 Recommendation

**Go with separate repositories** because:
1. **Cleaner deployments** - Each service deploys independently
2. **Better CI/CD performance** - Faster builds
3. **Team collaboration** - Different teams can work on different repos
4. **Security** - Separate access controls
5. **Scaling** - Easy to add microservices later

Would you like me to help you set up the separate repositories?
