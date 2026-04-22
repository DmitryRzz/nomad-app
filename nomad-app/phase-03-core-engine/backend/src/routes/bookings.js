const bookingService = require('../services/bookingService');

async function routes(fastify, options) {
  // GET /bookings/search - Search activities
  fastify.get('/search', async (request, reply) => {
    try {
      const { city, date, adults = 1 } = request.query;

      if (!city) {
        reply.code(400);
        return { success: false, error: 'City is required' };
      }

      const activities = await bookingService.searchActivities(
        city,
        date ? new Date(date) : new Date(),
        parseInt(adults)
      );

      return { success: true, data: activities };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });

  // POST /bookings - Create a booking
  fastify.post('/', async (request, reply) => {
    try {
      const userId = request.user?.id || 'demo-user';
      const {
        activityId,
        activityName,
        provider,
        date,
        adults,
        children,
        totalPrice,
        currency,
        contactEmail,
        contactPhone,
      } = request.body;

      const booking = await bookingService.createBooking({
        userId,
        activityId,
        activityName,
        provider,
        date: new Date(date),
        adults: parseInt(adults),
        children: children ? parseInt(children) : 0,
        totalPrice: parseFloat(totalPrice),
        currency: currency || 'USD',
        contactEmail,
        contactPhone,
      });

      reply.code(201);
      return { success: true, data: booking };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });

  // GET /bookings - Get user's bookings
  fastify.get('/', async (request, reply) => {
    try {
      const userId = request.user?.id || 'demo-user';
      const bookings = await bookingService.getUserBookings(userId);
      return { success: true, data: bookings };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });

  // PATCH /bookings/:id/cancel - Cancel booking
  fastify.patch('/:id/cancel', async (request, reply) => {
    try {
      const { id } = request.params;
      const booking = await bookingService.cancelBooking(id);
      return { success: true, data: booking };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });
}

module.exports = routes;
