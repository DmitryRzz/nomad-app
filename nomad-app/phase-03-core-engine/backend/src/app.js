const Fastify = require('fastify');
const cors = require('fastify-cors');
const config = require('./config');
const authMiddleware = require('./middleware/auth');

const app = Fastify({
  logger: true,
  pluginTimeout: 10000,
});

// Register plugins
app.register(cors, {
  origin: true,
  credentials: true,
});

// Auth middleware
app.register(authMiddleware);

// Health check
app.get('/health', async () => {
  return { status: 'ok', timestamp: new Date().toISOString() };
});

// Register routes
app.register(require('./routes/routes'), { prefix: '/routes' });
app.register(require('./routes/ai'), { prefix: '/ai' });
app.register(require('./routes/poi'), { prefix: '/poi' });
app.register(require('./routes/bookings'), { prefix: '/bookings' });
app.register(require('./routes/payments'), { prefix: '/payments' });
app.register(require('./routes/trips'), { prefix: '/trips' });

// Error handler
app.setErrorHandler((error, request, reply) => {
  app.log.error(error);
  reply.code(error.statusCode || 500).send({
    success: false,
    error: error.message,
  });
});

// Start server
const start = async () => {
  try {
    await app.listen({ port: config.port, host: '0.0.0.0' });
    app.log.info(`NOMAD API running on port ${config.port}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
};

start();
