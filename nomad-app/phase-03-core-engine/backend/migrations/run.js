const db = require('../config/database');

const migrations = [
  // 001: Create users table
  `
  CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100),
    avatar_url TEXT,
    native_language VARCHAR(10) DEFAULT 'ru',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
  );
  `,

  // 002: Create user_preferences table
  `
  CREATE TABLE IF NOT EXISTS user_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    interests TEXT[],
    budget_level INT CHECK (budget_level BETWEEN 1 AND 5),
    pace VARCHAR(20) CHECK (pace IN ('relaxed', 'balanced', 'intense')),
    accessibility_needs TEXT[],
    dietary_restrictions TEXT[],
    updated_at TIMESTAMP DEFAULT NOW()
  );
  `,

  // 003: Create poi table
  `
  CREATE TABLE IF NOT EXISTS poi (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL,
    subcategory VARCHAR(50),
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100),
    rating DECIMAL(2, 1) CHECK (rating BETWEEN 0 AND 5),
    review_count INT DEFAULT 0,
    price_level INT CHECK (price_level BETWEEN 1 AND 5),
    indoor BOOLEAN DEFAULT FALSE,
    accessibility_friendly BOOLEAN DEFAULT FALSE,
    opening_hours JSONB,
    tags TEXT[],
    source VARCHAR(50),
    external_id VARCHAR(255),
    must_see BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
  );
  `,

  // 004: Create routes table
  `
  CREATE TABLE IF NOT EXISTS routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100),
    start_date DATE,
    end_date DATE,
    status VARCHAR(20) DEFAULT 'draft',
    total_distance_km DECIMAL(10,2),
    estimated_duration_hours INT,
    weather_adapted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
  );
  `,

  // 005: Create route_stops table
  `
  CREATE TABLE IF NOT EXISTS route_stops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
    poi_id UUID REFERENCES poi(id),
    sequence_number INT NOT NULL,
    planned_time TIMESTAMP,
    duration_minutes INT DEFAULT 60,
    notes TEXT,
    visited BOOLEAN DEFAULT FALSE,
    skipped BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP DEFAULT NOW()
  );
  `,

  // 006: Create reviews table
  `
  CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poi_id UUID REFERENCES poi(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    text TEXT,
    language VARCHAR(10),
    source VARCHAR(50) DEFAULT 'app',
    created_at TIMESTAMP DEFAULT NOW()
  );
  `,

  // 007: Create translation_cache table
  `
  CREATE TABLE IF NOT EXISTS translation_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_text TEXT NOT NULL,
    source_lang VARCHAR(10) NOT NULL,
    target_lang VARCHAR(10) NOT NULL,
    translated_text TEXT NOT NULL,
    model VARCHAR(50) DEFAULT 'gpt-4',
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(source_text, source_lang, target_lang)
  );
  `,

  // 008: Add PostGIS extension and spatial index
  `
  CREATE EXTENSION IF NOT EXISTS postgis;
  `,

  // 009: Add spatial index to poi
  `
  CREATE INDEX IF NOT EXISTS idx_poi_location ON poi 
  USING GIST (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326));
  `,

  // 010: Create indexes for common queries
  `
  CREATE INDEX IF NOT EXISTS idx_routes_user_id ON routes(user_id);
  `,
  `
  CREATE INDEX IF NOT EXISTS idx_route_stops_route_id ON route_stops(route_id);
  `,
  `
  CREATE INDEX IF NOT EXISTS idx_poi_city ON poi(city);
  `,
  `
  CREATE INDEX IF NOT EXISTS idx_reviews_poi_id ON reviews(poi_id);
  `,

  // 011: Create bookings table
  `
  CREATE TABLE IF NOT EXISTS bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    activity_id VARCHAR(255) NOT NULL,
    activity_name VARCHAR(255) NOT NULL,
    provider VARCHAR(50) DEFAULT 'getyourguide',
    booking_date TIMESTAMP NOT NULL,
    adults INT NOT NULL DEFAULT 1,
    children INT DEFAULT 0,
    total_price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    status VARCHAR(20) DEFAULT 'pending',
    confirmation_code VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
  );
  `,

  // 012: Create payments table
  `
  CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    stripe_payment_intent_id VARCHAR(255),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) DEFAULT 'pending',
    description TEXT,
    related_booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
    related_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
  );
  `,

  // 013: Create subscriptions table
  `
  CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    stripe_customer_id VARCHAR(255),
    stripe_subscription_id VARCHAR(255) UNIQUE,
    status VARCHAR(20) DEFAULT 'incomplete',
    plan_type VARCHAR(20) DEFAULT 'pro',
    current_period_start TIMESTAMP,
    current_period_end TIMESTAMP,
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
  );
  `,

  // 014: Create split payments table
  `
  CREATE TABLE IF NOT EXISTS split_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    total_amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    participant_count INT NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
  );
  `,

  // 015: Create split payment participants table
  `
  CREATE TABLE IF NOT EXISTS split_payment_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    split_payment_id UUID REFERENCES split_payments(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    payment_intent_id VARCHAR(255),
    paid_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
  );
  `,

  // 016: Add indexes for new tables
  `
  CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);
  `,
  `
  CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
  `,
  `
  CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
  `,
  `
  CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_id ON subscriptions(stripe_subscription_id);
  `,
];

async function runMigrations() {
  console.log('Running migrations...');
  
  for (let i = 0; i < migrations.length; i++) {
    try {
      await db.query(migrations[i]);
      console.log(`Migration ${String(i + 1).padStart(3, '0')} applied successfully`);
    } catch (error) {
      console.error(`Migration ${String(i + 1).padStart(3, '0')} failed:`, error.message);
      // Continue with next migration
    }
  }

  console.log('Migrations completed');
  process.exit(0);
}

if (require.main === module) {
  runMigrations();
}

module.exports = { runMigrations, migrations };
