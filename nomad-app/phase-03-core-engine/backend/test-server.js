const Fastify = require('fastify');
const cors = require('fastify-cors');

const app = Fastify({
  logger: true,
  pluginTimeout: 10000,
});

// Register plugins
app.register(cors, {
  origin: true,
  credentials: true,
});

// Mock auth middleware
app.addHook('preHandler', async (request, reply) => {
  request.user = { userId: 'test-user-123' };
});

// Health check
app.get('/health', async () => {
  return { status: 'ok', timestamp: new Date().toISOString() };
});

// Mock trips routes for testing
app.register(require('./src/routes/trips'), { prefix: '/trips' });

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
    await app.listen({ port: 3001, host: '0.0.0.0' });
    app.log.info(`NOMAD Test API running on port 3001`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
};

start();
