const jwt = require('jsonwebtoken');
const config = require('../config');

// Simple auth middleware for development
// In production, use proper JWT validation
async function authMiddleware(fastify) {
  fastify.addHook('onRequest', async (request, reply) => {
    // Skip auth for public routes
    if (request.url.startsWith('/health') || request.url.startsWith('/ai/')) {
      return;
    }

    const authHeader = request.headers.authorization;
    
    if (!authHeader) {
      reply.code(401);
      throw new Error('Authorization header required');
    }

    const token = authHeader.replace('Bearer ', '');
    
    try {
      const decoded = jwt.verify(token, config.jwt.secret);
      request.user = decoded;
    } catch (error) {
      reply.code(401);
      throw new Error('Invalid token');
    }
  });
}

module.exports = authMiddleware;
