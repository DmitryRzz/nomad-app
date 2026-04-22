const paymentService = require('../services/paymentService');

async function routes(fastify, options) {
  // POST /payments/intent - Create payment intent
  fastify.post('/intent', async (request, reply) => {
    try {
      const { amount, currency, metadata } = request.body;
      const userId = request.user?.id || 'demo-user';

      if (!amount || !currency) {
        reply.code(400);
        return { success: false, error: 'Amount and currency are required' };
      }

      const intent = await paymentService.createPaymentIntent({
        amount: parseFloat(amount),
        currency,
        userId,
        metadata,
      });

      return { success: true, data: intent };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });

  // POST /payments/record - Record a payment
  fastify.post('/record', async (request, reply) => {
    try {
      const {
        paymentIntentId,
        amount,
        currency,
        status,
        description,
        relatedBookingId,
        relatedType,
      } = request.body;
      const userId = request.user?.id || 'demo-user';

      const payment = await paymentService.recordPayment({
        userId,
        paymentIntentId,
        amount: parseFloat(amount),
        currency,
        status,
        description,
        relatedBookingId,
        relatedType,
      });

      return { success: true, data: payment };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });

  // GET /payments/history - Get payment history
  fastify.get('/history', async (request, reply) => {
    try {
      const userId = request.user?.id || 'demo-user';
      const payments = await paymentService.getUserPayments(userId);
      return { success: true, data: payments };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });

  // POST /payments/subscription - Create Pro subscription
  fastify.post('/subscription', async (request, reply) => {
    try {
      const { priceId, customerEmail } = request.body;
      const userId = request.user?.id || 'demo-user';

      if (!priceId || !customerEmail) {
        reply.code(400);
        return { success: false, error: 'Price ID and email are required' };
      }

      const subscription = await paymentService.createSubscription({
        userId,
        priceId,
        customerEmail,
      });

      return { success: true, data: subscription };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });

  // DELETE /payments/subscription/:id - Cancel subscription
  fastify.delete('/subscription/:id', async (request, reply) => {
    try {
      const { id } = request.params;
      const result = await paymentService.cancelSubscription(id);
      return { success: true, data: result };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });

  // GET /payments/subscription - Get active subscription
  fastify.get('/subscription', async (request, reply) => {
    try {
      const userId = request.user?.id || 'demo-user';
      const subscription = await paymentService.getActiveSubscription(userId);
      return { success: true, data: subscription };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });

  // POST /payments/split - Create split payment
  fastify.post('/split', async (request, reply) => {
    try {
      const { totalAmount, currency, participants, description } = request.body;

      const split = await paymentService.createSplitPayment({
        totalAmount: parseFloat(totalAmount),
        currency,
        participants,
        description,
      });

      reply.code(201);
      return { success: true, data: split };
    } catch (error) {
      reply.code(500);
      return { success: false, error: error.message };
    }
  });
}

module.exports = routes;