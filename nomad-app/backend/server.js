const Fastify = require('fastify');
const cors = require('@fastify/cors');
const jwt = require('@fastify/jwt');
const bcrypt = require('bcryptjs');
const Database = require('better-sqlite3');
const { v4: uuidv4 } = require('uuid');

const fastify = Fastify({ logger: true });

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'nomad-dev-secret-change-in-production';

// Register plugins
fastify.register(cors, {
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization']
});

fastify.register(jwt, {
  secret: JWT_SECRET,
  sign: { expiresIn: '15m' },
  verify: { maxAge: '15m' }
});

// Initialize SQLite DB
const db = new Database('/tmp/nomad_api.db');

// Create tables
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    name TEXT,
    avatar_url TEXT,
    subscription_tier TEXT DEFAULT 'free',
    created_at INTEGER DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER DEFAULT (strftime('%s', 'now'))
  );

  CREATE TABLE IF NOT EXISTS routes (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    city TEXT NOT NULL,
    country TEXT NOT NULL,
    status TEXT DEFAULT 'active',
    estimated_duration_hours INTEGER,
    tags TEXT,
    created_at INTEGER DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER DEFAULT (strftime('%s', 'now')),
    FOREIGN KEY (user_id) REFERENCES users(id)
  );

  CREATE TABLE IF NOT EXISTS route_stops (
    id TEXT PRIMARY KEY,
    route_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    latitude REAL,
    longitude REAL,
    order_index INTEGER,
    visited INTEGER DEFAULT 0,
    FOREIGN KEY (route_id) REFERENCES routes(id) ON DELETE CASCADE
  );

  CREATE TABLE IF NOT EXISTS poi (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    latitude REAL,
    longitude REAL,
    city TEXT,
    country TEXT,
    rating REAL,
    image_url TEXT
  );

  CREATE TABLE IF NOT EXISTS refresh_tokens (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    token TEXT NOT NULL,
    expires_at INTEGER,
    created_at INTEGER DEFAULT (strftime('%s', 'now'))
  );
`);

// Seed demo data
const routeCount = db.prepare('SELECT COUNT(*) as count FROM routes').get();
if (routeCount.count === 0) {
  // Create demo user first
  db.prepare(`
    INSERT OR IGNORE INTO users (id, email, password, name)
    VALUES ('demo-user', 'demo@nomad.app', '$2a$12$dummyhash', 'Demo Traveler')
  `).run();

  const demoRoutes = [
    {
      id: 'route-1',
      user_id: 'demo-user',
      title: 'Romantic Paris Weekend',
      city: 'Paris',
      country: 'France',
      estimated_duration_hours: 48,
      tags: 'romantic,culture,food'
    },
    {
      id: 'route-2',
      user_id: 'demo-user',
      title: 'Tokyo Food Tour',
      city: 'Tokyo',
      country: 'Japan',
      estimated_duration_hours: 72,
      tags: 'food,adventure,nightlife'
    },
    {
      id: 'route-3',
      user_id: 'demo-user',
      title: 'Bali Beach Hop',
      city: 'Bali',
      country: 'Indonesia',
      estimated_duration_hours: 120,
      tags: 'beach,relax,nature'
    },
    {
      id: 'route-4',
      user_id: 'demo-user',
      title: 'New York in 3 Days',
      city: 'New York',
      country: 'USA',
      estimated_duration_hours: 72,
      tags: 'city,art,shopping'
    },
    {
      id: 'route-5',
      user_id: 'demo-user',
      title: 'Barcelona Gaudi Trail',
      city: 'Barcelona',
      country: 'Spain',
      estimated_duration_hours: 36,
      tags: 'architecture,culture,food'
    }
  ];

  const insertRoute = db.prepare(`
    INSERT INTO routes (id, user_id, title, city, country, estimated_duration_hours, tags)
    VALUES (@id, @user_id, @title, @city, @country, @estimated_duration_hours, @tags)
  `);

  demoRoutes.forEach(route => insertRoute.run(route));

  // Add stops for Paris route
  const parisStops = [
    { id: 'stop-1', route_id: 'route-1', name: 'Eiffel Tower', description: 'Iconic iron lattice tower', latitude: 48.8584, longitude: 2.2945, order_index: 0 },
    { id: 'stop-2', route_id: 'route-1', name: 'Louvre Museum', description: 'World\'s largest art museum', latitude: 48.8606, longitude: 2.3376, order_index: 1 },
    { id: 'stop-3', route_id: 'route-1', name: 'Notre-Dame', description: 'Medieval Catholic cathedral', latitude: 48.8530, longitude: 2.3499, order_index: 2 },
    { id: 'stop-4', route_id: 'route-1', name: 'Montmartre', description: 'Artistic hilltop neighborhood', latitude: 48.8867, longitude: 2.3431, order_index: 3 }
  ];

  const insertStop = db.prepare(`
    INSERT INTO route_stops (id, route_id, name, description, latitude, longitude, order_index)
    VALUES (@id, @route_id, @name, @description, @latitude, @longitude, @order_index)
  `);

  parisStops.forEach(stop => insertStop.run(stop));

  // Seed POI data
  const poiData = [
    { id: 'poi-1', name: 'Sagrada Familia', description: 'Gaudi\'s unfinished masterpiece', category: 'architecture', latitude: 41.4036, longitude: 2.1744, city: 'Barcelona', country: 'Spain', rating: 4.8 },
    { id: 'poi-2', name: 'Park Guell', description: 'Colorful mosaic park', category: 'park', latitude: 41.4145, longitude: 2.1527, city: 'Barcelona', country: 'Spain', rating: 4.6 },
    { id: 'poi-3', name: 'Senso-ji Temple', description: 'Ancient Buddhist temple', category: 'temple', latitude: 35.7148, longitude: 139.7967, city: 'Tokyo', country: 'Japan', rating: 4.7 },
    { id: 'poi-4', name: 'Shibuya Crossing', description: 'World\'s busiest pedestrian crossing', category: 'landmark', latitude: 35.6595, longitude: 139.7004, city: 'Tokyo', country: 'Japan', rating: 4.5 },
    { id: 'poi-5', name: 'Uluwatu Temple', description: 'Cliffside Hindu temple', category: 'temple', latitude: -8.8291, longitude: 115.0849, city: 'Bali', country: 'Indonesia', rating: 4.6 }
  ];

  const insertPoi = db.prepare(`
    INSERT INTO poi (id, name, description, category, latitude, longitude, city, country, rating)
    VALUES (@id, @name, @description, @category, @latitude, @longitude, @city, @country, @rating)
  `);

  poiData.forEach(poi => insertPoi.run(poi));

  console.log('Demo data seeded');
}

// Auth middleware
async function authenticate(request, reply) {
  try {
    await request.jwtVerify();
    request.user = request.user;
  } catch (err) {
    reply.code(401).send({ error: 'Unauthorized' });
  }
}

// Routes

// Health check
fastify.get('/health', async () => ({ status: 'ok', timestamp: new Date().toISOString() }));

// Auth: Register
fastify.post('/auth/register', async (request, reply) => {
  const { email, password, name } = request.body;

  if (!email || !password) {
    return reply.code(400).send({ error: 'Email and password required' });
  }

  const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email);
  if (existing) {
    return reply.code(409).send({ error: 'Email already registered' });
  }

  const hashedPassword = bcrypt.hashSync(password, 12);
  const userId = uuidv4();

  db.prepare(`
    INSERT INTO users (id, email, password, name)
    VALUES (?, ?, ?, ?)
  `).run(userId, email, hashedPassword, name || email.split('@')[0]);

  const accessToken = fastify.jwt.sign({ userId, email });
  const refreshToken = uuidv4();

  db.prepare(`
    INSERT INTO refresh_tokens (id, user_id, token, expires_at)
    VALUES (?, ?, ?, strftime('%s', 'now', '+7 days'))
  `).run(uuidv4(), userId, refreshToken);

  return {
    accessToken,
    refreshToken,
    user: { id: userId, email, name: name || email.split('@')[0] }
  };
});

// Auth: Login
fastify.post('/auth/login', async (request, reply) => {
  const { email, password } = request.body;

  if (!email || !password) {
    return reply.code(400).send({ error: 'Email and password required' });
  }

  const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
  if (!user || !bcrypt.compareSync(password, user.password)) {
    return reply.code(401).send({ error: 'Invalid credentials' });
  }

  const accessToken = fastify.jwt.sign({ userId: user.id, email: user.email });
  const refreshToken = uuidv4();

  db.prepare(`
    INSERT INTO refresh_tokens (id, user_id, token, expires_at)
    VALUES (?, ?, ?, strftime('%s', 'now', '+7 days'))
  `).run(uuidv4(), user.id, refreshToken);

  return {
    accessToken,
    refreshToken,
    user: { id: user.id, email: user.email, name: user.name, subscriptionTier: user.subscription_tier }
  };
});

// Auth: Refresh token
fastify.post('/auth/refresh', async (request, reply) => {
  const { refreshToken } = request.body;

  const tokenRecord = db.prepare('SELECT * FROM refresh_tokens WHERE token = ? AND expires_at > strftime(\'%s\', \'now\')').get(refreshToken);
  if (!tokenRecord) {
    return reply.code(401).send({ error: 'Invalid refresh token' });
  }

  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(tokenRecord.user_id);
  if (!user) {
    return reply.code(401).send({ error: 'User not found' });
  }

  const accessToken = fastify.jwt.sign({ userId: user.id, email: user.email });

  return { accessToken };
});

// Get current user
fastify.get('/auth/me', { preHandler: authenticate }, async (request) => {
  const user = db.prepare('SELECT id, email, name, avatar_url, subscription_tier FROM users WHERE id = ?').get(request.user.userId);
  return { user };
});

// Routes: Get all routes for user
fastify.get('/routes', { preHandler: authenticate }, async (request) => {
  const routes = db.prepare(`
    SELECT r.*, COUNT(rs.id) as stops_count
    FROM routes r
    LEFT JOIN route_stops rs ON r.id = rs.route_id
    WHERE r.user_id = ?
    GROUP BY r.id
    ORDER BY r.created_at DESC
  `).all(request.user.userId);

  return { routes: routes.map(r => ({
    ...r,
    tags: r.tags ? r.tags.split(',') : [],
    stopsCount: r.stops_count
  })) };
});

// Routes: Get demo routes (no auth required for preview)
fastify.get('/routes/demo', async () => {
  const routes = db.prepare(`
    SELECT r.*, COUNT(rs.id) as stops_count
    FROM routes r
    LEFT JOIN route_stops rs ON r.id = rs.route_id
    WHERE r.user_id = 'demo-user'
    GROUP BY r.id
    ORDER BY r.created_at DESC
  `).all();

  return { routes: routes.map(r => ({
    ...r,
    tags: r.tags ? r.tags.split(',') : [],
    stopsCount: r.stops_count
  })) };
});

// Routes: Get single route
fastify.get('/routes/:id', { preHandler: authenticate }, async (request, reply) => {
  const route = db.prepare('SELECT * FROM routes WHERE id = ? AND user_id = ?').get(request.params.id, request.user.userId);
  if (!route) {
    return reply.code(404).send({ error: 'Route not found' });
  }

  const stops = db.prepare('SELECT * FROM route_stops WHERE route_id = ? ORDER BY order_index').all(request.params.id);

  return {
    route: { ...route, tags: route.tags ? route.tags.split(',') : [] },
    stops
  };
});

// Routes: Create route
fastify.post('/routes', { preHandler: authenticate }, async (request, reply) => {
  const { title, city, country, estimatedDurationHours, tags } = request.body;
  const routeId = uuidv4();

  db.prepare(`
    INSERT INTO routes (id, user_id, title, city, country, estimated_duration_hours, tags)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).run(routeId, request.user.userId, title, city, country, estimatedDurationHours || 0, tags ? tags.join(',') : '');

  const route = db.prepare('SELECT * FROM routes WHERE id = ?').get(routeId);
  return { route: { ...route, tags: route.tags ? route.tags.split(',') : [] } };
});

// POI: Get nearby POI by city
fastify.get('/poi/:city', async (request) => {
  const poi = db.prepare('SELECT * FROM poi WHERE city = ? ORDER BY rating DESC').all(request.params.city);
  return { poi };
});

// POI: Get all POI
fastify.get('/poi', async () => {
  const poi = db.prepare('SELECT * FROM poi ORDER BY rating DESC LIMIT 50').all();
  return { poi };
});

// Start server
const start = async () => {
  try {
    const port = process.env.PORT || 3000;
    await fastify.listen({ port, host: '0.0.0.0' });
    console.log(`Server running on port ${port}`);
    console.log(`API endpoints:`);
    console.log(`  POST /auth/register - Register new user`);
    console.log(`  POST /auth/login - Login`);
    console.log(`  POST /auth/refresh - Refresh access token`);
    console.log(`  GET /auth/me - Get current user`);
    console.log(`  GET /routes - Get user routes`);
    console.log(`  GET /routes/demo - Get demo routes (no auth)`);
    console.log(`  GET /routes/:id - Get route details`);
    console.log(`  POST /routes - Create route`);
    console.log(`  GET /poi - Get all POI`);
    console.log(`  GET /poi/:city - Get POI by city`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();
