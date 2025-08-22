# Pesagram E-Banking System

Pesagram is a full-stack e-banking application featuring a Node.js/Express backend with MongoDB and a Flutter frontend. It supports user authentication, wallet management, transactions, and Bitnob API integration for crypto operations.

---

## Table of Contents
- [Features](#features)
- [Project Structure](#project-structure)
- [Backend Setup](#backend-setup)
- [Frontend Setup](#frontend-setup)
- [Environment Variables](#environment-variables)
- [API Endpoints](#api-endpoints)
- [Development & Testing](#development--testing)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)

---

## Features
- User authentication (JWT)
- Wallet creation and management
- Transactions and audit logs
- Bitnob API integration (crypto wallets, swaps, Lightning, etc.)
- Mobile and web support (Flutter)
- Rate limiting and security best practices

---

## Project Structure
```
backend/    # Node.js/Express/MongoDB API
frontend/   # Flutter mobile/web app
```

---

## Backend Setup
1. **Install dependencies:**
   ```sh
   cd backend
   npm install
   ```
2. **Configure environment:**
   - Copy `.env.example` to `.env` and fill in your credentials (see [Environment Variables](#environment-variables)).
3. **Start the server:**
   ```sh
   npm start
   ```
   The server runs on `http://localhost:3000` by default.

---

## Frontend Setup
1. **Install Flutter dependencies:**
   ```sh
   cd frontend
   flutter pub get
   ```
2. **Run the app:**
   - For web: `flutter run -d chrome`
   - For Android/iOS: `flutter run`
3. **Configure API URL:**
   - Edit `lib/config/api_config.dart` to set your backend IP for mobile testing.

---

## Environment Variables
Backend `.env` example:
```
PORT=3000
MONGODB_URI=your_mongodb_uri
DB_NAME=pesagram
BITNOB_BASE_URL=https://sandboxapi.bitnob.co
BITNOB_API_KEY=your_bitnob_api_key
JWT_SECRET=your_jwt_secret
ALLOWED_ORIGINS=*
```

---

## API Endpoints
- `POST /api/auth/signup` — Register user
- `POST /api/auth/signin` — Login
- `GET /health` — Health check
- `POST /api/wallet` — Create wallet
- ...and more (see backend/routes)

---

## Development & Testing
- Use Postman or curl to test API endpoints
- For mobile device testing, ensure your PC and phone are on the same network and use your PC's IP address in the Flutter config
- MongoDB Atlas must allow your IP in its network access settings

---

## Deployment
- Backend can be deployed to Vercel, Heroku, or any Node.js host
- Frontend can be built for web or deployed to app stores

---

## Troubleshooting
- **Cannot connect from mobile:**
  - Ensure Windows Firewall allows inbound connections on backend port
  - Use your actual PC IP in Flutter config
  - MongoDB Atlas IP whitelist includes your current public IP
- **Database errors:**
  - Check `.env` for correct MongoDB URI and credentials
- **Bitnob API errors:**
  - Verify API key and base URL in `.env`

---

## License
MIT
