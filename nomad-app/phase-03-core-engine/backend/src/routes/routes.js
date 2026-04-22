const routeService = require('../services/routeService');

async function routes(fastify, options) {
  // GET /routes - Get all user routes
  fastify.get('/', async (request, reply) => {
    try {
      const userId = request.user.id; // Assuming auth middleware sets this
      const routes = await routeService.getUserRoutes(userId);
      return { success: true, data: routes };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });

  // POST /routes - Create new route
  fastify.post('/', async (request, reply) => {
    try {
      const userId = request.user.id;
      const { city, country, preferences } = request.body;

      if (!city) {
        reply.code(400);
        return { success: false, error: 'City is required' };
      }

      const route = await routeService.createRoute({
        userId,
        city,
        country,
        preferences,
      });

      reply.code(201);
      return { success: true, data: route };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });

  // GET /routes/:id - Get route details
  fastify.get('/:id', async (request, reply) => {
    try {
      const { id } = request.params;
      const route = await routeService.getRouteById(id);
      return { success: true, data: route };
    } catch (error) {
      reply.code(404);
      return { success: false, error: error.message };
    }
  });

  // DELETE /routes/:id - Delete route
  fastify.delete('/:id', async (request, reply) => {
    try {
      const { id } = request.params;
      await routeService.deleteRoute(id);
      return { success: true, message: 'Route deleted' };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });

  // PATCH /routes/stops/:stopId - Update stop status
  fastify.patch('/stops/:stopId', async (request, reply) => {
    try {
      const { stopId } = request.params;
      const { visited, skipped, notes } = request.body;
      
      const stop = await routeService.updateStop(stopId, {
        visited,
        skipped,
        notes,
      });

      return { success: true, data: stop };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });
}

module.exports = routes;
