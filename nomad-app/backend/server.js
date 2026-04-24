const fastify = require('fastify')({ logger: true });
const sqlite3 = require('better-sqlite3');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

// Database
const db = new sqlite3('/root/.openclaw/workspace/nomad-app/backend/nomad.db');

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'nomad-secret-key-2026';

// Middleware: Verify JWT
async function authenticate(request, reply) {
  try {
    const authHeader = request.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return reply.code(401).send({ error: 'No token provided' });
    }
    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, JWT_SECRET);
    request.user = decoded;
  } catch (err) {
    return reply.code(401).send({ error: 'Invalid token' });
  }
}

// Public routes (no auth required)
const publicRoutes = ['/auth/register', '/auth/login', '/auth/refresh', '/health'];

fastify.addHook('onRequest', async (request, reply) => {
  if (publicRoutes.includes(request.routerPath)) return;
  await authenticate(request, reply);
});

// ==================== AUTH ROUTES ====================

// Register
fastify.post('/auth/register', async (request, reply) => {
  const { email, password, name } = request.body;
  
  if (!email || !password) {
    return reply.code(400).send({ error: 'Email and password required' });
  }
  
  // Check if user exists
  const existing = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
  if (existing) {
    return reply.code(409).send({ error: 'User already exists' });
  }
  
  const id = uuidv4();
  const hashedPassword = await bcrypt.hash(password, 12);
  const now = Date.now();
  
  db.prepare('INSERT INTO users (id, email, password, name, created_at) VALUES (?, ?, ?, ?, ?)')
    .run(id, email, hashedPassword, name || email.split('@')[0], now);
  
  const accessToken = jwt.sign({ userId: id, email }, JWT_SECRET, { expiresIn: '15m' });
  const refreshToken = uuidv4();
  
  db.prepare('INSERT INTO user_sessions (id, user_id, token, created_at) VALUES (?, ?, ?, ?)')
    .run(uuidv4(), id, refreshToken, now);
  
  return reply.send({ accessToken, refreshToken, user: { id, email, name: name || email.split('@')[0] } });
});

// Login
fastify.post('/auth/login', async (request, reply) => {
  const { email, password } = request.body;
  
  const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
  if (!user) {
    return reply.code(401).send({ error: 'Invalid credentials' });
  }
  
  const valid = await bcrypt.compare(password, user.password);
  if (!valid) {
    return reply.code(401).send({ error: 'Invalid credentials' });
  }
  
  const accessToken = jwt.sign({ userId: user.id, email }, JWT_SECRET, { expiresIn: '15m' });
  const refreshToken = uuidv4();
  
  db.prepare('INSERT INTO user_sessions (id, user_id, token, created_at) VALUES (?, ?, ?, ?)')
    .run(uuidv4(), user.id, refreshToken, Date.now());
  
  return reply.send({ 
    accessToken, 
    refreshToken, 
    user: { id: user.id, email: user.email, name: user.name } 
  });
});

// Refresh Token
fastify.post('/auth/refresh', async (request, reply) => {
  const { refreshToken } = request.body;
  
  const session = db.prepare('SELECT * FROM user_sessions WHERE token = ?').get(refreshToken);
  if (!session) {
    return reply.code(401).send({ error: 'Invalid refresh token' });
  }
  
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(session.user_id);
  const accessToken = jwt.sign({ userId: user.id, email: user.email }, JWT_SECRET, { expiresIn: '15m' });
  
  return reply.send({ accessToken, user: { id: user.id, email: user.email, name: user.name } });
});

// Get Current User
fastify.get('/auth/me', async (request, reply) => {
  const user = db.prepare('SELECT id, email, name, created_at FROM users WHERE id = ?').get(request.user.userId);
  return reply.send({ user });
});

// ==================== ROUTE ROUTES ====================

// Get Demo Routes (no auth)
fastify.get('/routes/demo', async (request, reply) => {
  const routes = db.prepare('SELECT * FROM routes WHERE user_id = ?').all('demo-user');
  
  const routesWithStops = routes.map(route => {
    const stops = db.prepare('SELECT * FROM route_stops WHERE route_id = ? ORDER BY stop_order').all(route.id);
    return { ...route, stops };
  });
  
  return reply.send({ routes: routesWithStops });
});

// Get User Routes
fastify.get('/routes', async (request, reply) => {
  const routes = db.prepare('SELECT * FROM routes WHERE user_id = ?').all(request.user.userId);
  
  const routesWithStops = routes.map(route => {
    const stops = db.prepare('SELECT * FROM route_stops WHERE route_id = ? ORDER BY stop_order').all(route.id);
    return { ...route, stops };
  });
  
  return reply.send({ routes: routesWithStops });
});

// ==================== AI GENERATION ====================

// Generate AI Route
fastify.post('/trips/generate', async (request, reply) => {
  const { destination, duration, budget, intensity } = request.body;
  
  // Simulate AI processing
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  // Generate mock itinerary
  const activities = [
    'Visit historic city center', 'Explore local markets', 'Try authentic cuisine',
    'Visit famous landmarks', 'Take a walking tour', 'Enjoy sunset viewpoint',
    'Visit museum or gallery', 'Explore neighborhood cafes', 'Local food tasting',
    'Shopping in boutique district', 'Relax in city park', 'Nightlife exploration'
  ];
  
  const days = [];
  for (let i = 1; i <= duration; i++) {
    const dayActivities = [];
    const numActivities = intensity === 'relaxed' ? 2 : intensity === 'intense' ? 5 : 3;
    
    for (let j = 0; j < numActivities; j++) {
      dayActivities.push({
        name: activities[Math.floor(Math.random() * activities.length)],
        time: `${9 + j * 2}:00`,
        duration: '2h',
        cost: budget === 'budget' ? '$10' : budget === 'luxury' ? '$50' : '$25'
      });
    }
    
    days.push({
      day: i,
      date: new Date(Date.now() + i * 86400000).toISOString().split('T')[0],
      activities: dayActivities
    });
  }
  
  const trip = {
    id: 'trip-' + uuidv4(),
    title: `${duration}-Day ${destination} Adventure`,
    destination,
    duration,
    budget,
    intensity,
    days,
    created_at: Date.now()
  };
  
  return reply.send({ trip });
});

// ==================== POI ROUTES ====================

// Get POI by City
fastify.get('/poi/:city', async (request, reply) => {
  const { city } = request.params;
  const pois = db.prepare('SELECT * FROM poi WHERE city = ?').all(city);
  return reply.send({ pois });
});

// Health Check
fastify.get('/health', async (request, reply) => {
  return reply.send({ status: 'ok', timestamp: new Date().toISOString() });
});

// Start server
const start = async () => {
  try {
    await fastify.listen({ port: 3000, host: '0.0.0.0' });
    console.log('Server running on http://0.0.0.0:3000');
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

start();
