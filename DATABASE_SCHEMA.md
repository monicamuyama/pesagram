# Database Schema for Monikhangu Application

## Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    bitnob_customer_id VARCHAR(255),
    email_verified BOOLEAN DEFAULT FALSE,
    kyc_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

## User Wallets Table
```sql
CREATE TABLE user_wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    bitnob_wallet_id VARCHAR(255),
    currency VARCHAR(10) NOT NULL,
    wallet_type ENUM('bitcoin', 'lightning', 'stablecoin') NOT NULL,
    label VARCHAR(100),
    balance DECIMAL(20, 8) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

## Transactions Table
```sql
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    bitnob_transaction_id VARCHAR(255),
    from_wallet_id UUID REFERENCES user_wallets(id),
    to_address VARCHAR(255),
    amount DECIMAL(20, 8) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    transaction_type ENUM('send', 'receive', 'swap') NOT NULL,
    status ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'pending',
    description TEXT,
    fees DECIMAL(20, 8) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

## Bitcoin Addresses Table
```sql
CREATE TABLE bitcoin_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    wallet_id UUID REFERENCES user_wallets(id) ON DELETE CASCADE,
    address VARCHAR(255) UNIQUE NOT NULL,
    label VARCHAR(100),
    is_used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Audit Logs Table
```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Recommended Database Setup

### Option 1: PostgreSQL (Recommended for Production)
```bash
# Install PostgreSQL
npm install pg sequelize sequelize-cli

# Create database connection
DATABASE_URL=postgresql://username:password@localhost:5432/monikhangu_db
```

### Option 2: SQLite (Good for Development)
```bash
# Install SQLite
npm install sqlite3 sequelize

# Database file
DATABASE_URL=sqlite:./monikhangu.db
```

### Option 3: MongoDB (Alternative NoSQL)
```bash
# Install MongoDB driver
npm install mongoose

# Connection string
MONGODB_URI=mongodb://localhost:27017/monikhangu
```
