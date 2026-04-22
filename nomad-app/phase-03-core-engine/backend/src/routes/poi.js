const poiService = require('../services/poiService');

async function routes(fastify, options) {
  // GET /poi/nearby - Find POIs near location
  fastify.get('/nearby', async (request, reply) => {
    try {
      const { 
        lat, 
        lng, 
        radius = 500, 
        category,
        interests,
        limit = 20 
      } = request.query;

      if (!lat || !lng) {
        reply.code(400);
        return { success: false, error: 'lat and lng are required' };
      }

      const interestList = interests ? interests.split(',') : [];

      const pois = await poiService.findNearby(
        parseFloat(lat),
        parseFloat(lng),
        parseInt(radius),
        category,
        interestList,
        parseInt(limit)
      );

      return { success: true, data: pois };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });

  // GET /poi/:id - Get POI details
  fastify.get('/:id', async (request, reply) => {
    try {
      const { id } = request.params;
      const poi = await poiService.getById(id);

      if (!poi) {
        reply.code(404);
        return { success: false, error: 'POI not found' };
      }

      return { success: true, data: poi };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });

  // GET /poi/city/:city - Get POIs by city
  fastify.get('/city/:city', async (request, reply) => {
    try {
      const { city } = request.params;
      const { category, limit = 50 } = request.query;

      const pois = await poiService.getByCity(city, category, parseInt(limit));
      return { success: true, data: pois };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });
}

module.exports = routes;
