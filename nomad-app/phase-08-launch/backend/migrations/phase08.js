const db = require('../config/database');

const migrations = [
  // 017: Create fcm_tokens table for push notifications
  `
  CREATE TABLE IF NOT EXISTS fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    device_type VARCHAR(20) CHECK (device_type IN ('ios', 'android', 'web')),
    device_id VARCHAR(255),
    app_version VARCHAR(50),
    locale VARCHAR(10),
    is_active BOOLEAN DEFAULT TRUE,
    last_used_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, device_id)
  );
  `,

  // 018: Create notifications table for in-app notifications
  `
  CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'general',
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
  );
  `,

  // 019: Create user_sessions table for multi-device session management
  `
  CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(255) NOT NULL,
    device_info JSONB,
    ip_address INET,
    expires_at TIMESTAMP NOT NULL,
    revoked_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
  );
  `,

  // 020: Add password_reset_token to users
  `
  ALTER TABLE users ADD COLUMN IF NOT EXISTS password_reset_token VARCHAR(255);
  `,
  `
  ALTER TABLE users ADD COLUMN IF NOT EXISTS password_reset_expires TIMESTAMP;
  `,

  // 021: Add email_verified to users
  `
  ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;
  `,
  `
  ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verification_token VARCHAR(255);
  `,

  // 022: Add indexes
  `
  CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens(user_id);
  `,
  `
  CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
  `,
  `
  CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
  `,
  `
  CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
  `,
  `
  CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON user_sessions(refresh_token_hash);
  `,
];

async function runMigrations() {
  console.log('Running Phase 08 migrations...');
  
  for (let i = 0; i < migrations.length; i++) {
    try {
      await db.query(migrations[i]);
      console.log(`Migration ${String(i + 17).padStart(3, '0')} applied successfully`);
    } catch (error) {
      console.error(`Migration ${String(i + 17).padStart(3, '0')} failed:`, error.message);
    }
  }

  console.log('Phase 08 migrations completed');
  process.exit(0);
}

if (require.main === module) {
  runMigrations();
}

module.exports = { runMigrations, migrations };
