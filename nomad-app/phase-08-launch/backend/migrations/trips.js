const { v4: uuidv4 } = require('uuid');

module.exports = {
  up: async (pg) => {
    // Trips table
    await pg.query(`
      CREATE TABLE IF NOT EXISTS trips (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        destination VARCHAR(255) NOT NULL,
        country VARCHAR(100),
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        status VARCHAR(50) DEFAULT 'draft',
        budget_level VARCHAR(50) DEFAULT 'moderate',
        intensity VARCHAR(50) DEFAULT 'balanced',
        transport_mode VARCHAR(50) DEFAULT 'mixed',
        total_budget DECIMAL(10,2),
        spent_budget DECIMAL(10,2) DEFAULT 0,
        interests JSONB DEFAULT '[]',
        cuisines JSONB DEFAULT '[]',
        wake_up_time VARCHAR(10),
        sleep_time VARCHAR(10),
        travelers_count INTEGER DEFAULT 1,
        special_requirements TEXT,
        generation_progress INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Trip days table
    await pg.query(`
      CREATE TABLE IF NOT EXISTS trip_days (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
        day_number INTEGER NOT NULL,
        date DATE NOT NULL,
        theme VARCHAR(255),
        day_budget DECIMAL(10,2),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Trip activities table
    await pg.query(`
      CREATE TABLE IF NOT EXISTS trip_activities (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        trip_day_id UUID NOT NULL REFERENCES trip_days(id) ON DELETE CASCADE,
        trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        category VARCHAR(50) DEFAULT 'sightseeing',
        poi_id VARCHAR(100),
        poi_name VARCHAR(255),
        start_time TIME,
        end_time TIME,
        duration_minutes INTEGER DEFAULT 60,
        cost DECIMAL(10,2),
        currency VARCHAR(10) DEFAULT 'USD',
        latitude DECIMAL(10, 8),
        longitude DECIMAL(11, 8),
        address TEXT,
        completed BOOLEAN DEFAULT FALSE,
        skipped BOOLEAN DEFAULT FALSE,
        notes TEXT,
        booking_url TEXT,
        image_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Indexes
    await pg.query(`CREATE INDEX IF NOT EXISTS idx_trips_user_id ON trips(user_id)`);
    await pg.query(`CREATE INDEX IF NOT EXISTS idx_trips_status ON trips(status)`);
    await pg.query(`CREATE INDEX IF NOT EXISTS idx_trip_days_trip_id ON trip_days(trip_id)`);
    await pg.query(`CREATE INDEX IF NOT EXISTS idx_trip_activities_trip_id ON trip_activities(trip_id)`);
    await pg.query(`CREATE INDEX IF NOT EXISTS idx_trip_activities_completed ON trip_activities(completed)`);

    console.log('Trip tables migration completed');
  },

  down: async (pg) => {
    await pg.query('DROP TABLE IF EXISTS trip_activities CASCADE');
    await pg.query('DROP TABLE IF EXISTS trip_days CASCADE');
    await pg.query('DROP TABLE IF EXISTS trips CASCADE');
    console.log('Trip tables migration rolled back');
  }
};
