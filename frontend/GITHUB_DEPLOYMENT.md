# Pesagram - GitHub Deployment Guide

## 🚀 Automated Deployment Setup

This repository includes automated CI/CD pipelines for deploying your Pesagram application to multiple platforms.

### 📋 Prerequisites

Before pushing to GitHub, ensure you have the following secrets configured in your repository:

#### Repository Settings → Secrets and Variables → Actions

**Required Secrets:**
```
VERCEL_TOKEN=your_vercel_token_here
VERCEL_ORG_ID=your_vercel_org_id_here
VERCEL_PROJECT_ID=your_vercel_project_id_here
```

### 🔧 Setup Instructions

#### 1. **Vercel Setup**
```bash
# Install Vercel CLI
npm install -g vercel

# Login to Vercel
vercel login

# Get your Vercel token
# Go to https://vercel.com/account/tokens
# Create a new token and copy it

# Get Organization ID and Project ID
cd backend
vercel link
# This will create .vercel/project.json with your IDs
```

#### 2. **GitHub Repository Setup**
```bash
# Add all files to git
git add .

# Commit your changes
git commit -m "feat: Initial Pesagram setup with automated deployment"

# Push to GitHub
git push origin main
```

#### 3. **GitHub Pages Setup (for Web App)**
1. Go to your repository → Settings → Pages
2. Source: "GitHub Actions"
3. The workflow will automatically deploy your Flutter web app

### 🔄 Deployment Workflows

#### **Backend Deployment** (`deploy-backend.yml`)
- **Triggers:** Push to `main` branch with backend changes
- **Target:** Vercel serverless functions
- **Includes:** 
  - Node.js setup
  - Dependency installation
  - Testing
  - Automatic Vercel deployment

#### **Flutter CI/CD** (`flutter-ci.yml`)
- **Triggers:** Push/PR to `main` branch
- **Includes:**
  - Code formatting verification
  - Static analysis
  - Unit tests
  - Android APK/AAB builds
  - iOS builds (macOS runner)
  - Web builds

#### **Web App Deployment** (`deploy-web.yml`)
- **Triggers:** Push to `main` with Flutter changes
- **Target:** GitHub Pages
- **URL:** `https://yourusername.github.io/pesagram/`

### 📱 Release Process

#### **Development Workflow:**
1. Create feature branch: `git checkout -b feature/new-feature`
2. Make changes and commit
3. Push and create PR
4. CI runs tests and builds
5. Merge to `main` triggers deployments

#### **Production Deployment:**
1. Backend automatically deploys to Vercel
2. Web app deploys to GitHub Pages
3. Mobile builds are available as artifacts

### 🔐 Environment Variables

#### **Vercel Environment Variables:**
Copy from `backend/.env.production` to your Vercel dashboard:

```bash
# Core Configuration
NODE_ENV=production
MONGODB_URI=your_mongodb_atlas_connection_string
JWT_SECRET=your_production_jwt_secret

# Bitnob API
BITNOB_BASE_URL=https://api.bitnob.co/api
BITNOB_API_KEY=your_production_bitnob_api_key
BITNOB_ENVIRONMENT=production

# Security
ALLOWED_ORIGINS=https://yourusername.github.io
```

### 📊 Monitoring Deployments

#### **Vercel Dashboard:**
- Monitor backend deployments
- View function logs
- Check performance metrics
- Configure custom domains

#### **GitHub Actions:**
- View workflow runs in Actions tab
- Download build artifacts
- Monitor deployment status
- Check logs for debugging

### 🔧 Manual Deployment Commands

#### **Backend:**
```bash
cd backend
vercel --prod
```

#### **Flutter Web:**
```bash
flutter build web --release
# Deploy build/web/ to your hosting provider
```

#### **Android:**
```bash
flutter build apk --release
flutter build appbundle --release
```

#### **iOS:**
```bash
flutter build ios --release
```

### 🐛 Troubleshooting

#### **Common Issues:**

1. **Vercel Deployment Fails:**
   - Check environment variables
   - Verify API keys
   - Check function timeout limits

2. **Flutter Build Fails:**
   - Update Flutter version
   - Clear build cache: `flutter clean`
   - Check dependencies: `flutter pub deps`

3. **GitHub Pages Not Working:**
   - Enable Pages in repository settings
   - Check base-href in build command
   - Verify workflow permissions

#### **Debug Commands:**
```bash
# Check Flutter doctor
flutter doctor -v

# Analyze project
flutter analyze

# Test locally
flutter run -d web-server --web-port 8080
```

### 📚 Additional Resources

- [Vercel Documentation](https://vercel.com/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter Deployment Guide](https://docs.flutter.dev/deployment)
- [Bitnob API Documentation](https://docs.bitnob.com)

### 🎯 Next Steps After Deployment

1. **Configure Custom Domain** (Vercel + GitHub Pages)
2. **Set up Monitoring** (Sentry, LogRocket)
3. **Configure Analytics** (Google Analytics, Mixpanel)
4. **Set up Error Tracking**
5. **Configure Push Notifications**
6. **Set up App Store/Play Store Publishing**

---

**🎉 Your Pesagram application is now ready for automated deployment!**
