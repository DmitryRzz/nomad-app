const jwt = require('jsonwebtoken');
const config = require('../config');

// Public routes that don't require authentication
const PUBLIC_ROUTES = [
  '/health',
  '/auth/login',
  '/auth/register',
  '/auth/refresh',
  '/auth/password-reset-request',
  '/auth/password-reset',
];

function isPublicRoute(url) {
  return PUBLIC_ROUTES.some(route => url.startsWith(route));
}

async function authMiddleware(fastify) {
  fastify.addHook('onRequest', async (request, reply) => {
    if (isPublicRoute(request.url)) {
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
      
      if (decoded.type && decoded.type !== 'access') {
        reply.code(401);
        throw new Error('Invalid token type');
      }
      
      request.user = decoded;
    } catch (error) {
      reply.code(401);
      throw new Error('Invalid or expired token');
    }
  });
}

module.exports = authMiddleware;
