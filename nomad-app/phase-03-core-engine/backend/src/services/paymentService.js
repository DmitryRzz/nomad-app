const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY || 'sk_test_placeholder');
const db = require('../config/database');

class PaymentService {
  /**
   * Create a payment intent
   * @param {Object} params - Payment parameters
   * @returns {Promise<Object>} Payment intent
   */
  async createPaymentIntent(params) {
    const { amount, currency, userId, metadata = {} } = params;

    try {
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100), // Convert to cents
        currency: currency.toLowerCase(),
        automatic_payment_methods: { enabled: true },
        metadata: {
          userId,
          ...metadata,
        },
      });

      return {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      };
    } catch (error) {
      console.error('Stripe payment intent failed:', error);
      throw error;
    }
  }

  /**
   * Record a payment in database
   * @param {Object} params - Payment details
   * @returns {Promise<Object>} Created payment record
   */
  async recordPayment(params) {
    const {
      userId,
      paymentIntentId,
      amount,
      currency,
      status,
      description,
      relatedBookingId,
      relatedType,
    } = params;

    const result = await db.query(
      `INSERT INTO payments (
        user_id, stripe_payment_intent_id, amount, currency,
        status, description, related_booking_id, related_type
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *`,
      [
        userId,
        paymentIntentId,
        amount,
        currency,
        status,
        description,
        relatedBookingId,
        relatedType,
      ]
    );

    return result.rows[0];
  }

  /**
   * Get user's payment history
   * @param {string} userId - User UUID
   * @returns {Promise<Array>} Payment history
   */
  async getUserPayments(userId) {
    const result = await db.query(
      `SELECT * FROM payments WHERE user_id = $1 ORDER BY created_at DESC`,
      [userId]
    );
    return result.rows;
  }

  /**
   * Process refund
   * @param {string} paymentIntentId - Stripe payment intent ID
   * @param {number} amount - Refund amount (optional, full refund if null)
   * @returns {Promise<Object>} Refund result
   */
  async refundPayment(paymentIntentId, amount = null) {
    try {
      const refundParams = { payment_intent: paymentIntentId };
      if (amount) {
        refundParams.amount = Math.round(amount * 100);
      }

      const refund = await stripe.refunds.create(refundParams);

      // Update payment status
      await db.query(
        `UPDATE payments SET status = 'refunded', updated_at = NOW() 
         WHERE stripe_payment_intent_id = $1`,
        [paymentIntentId]
      );

      return refund;
    } catch (error) {
      console.error('Refund failed:', error);
      throw error;
    }
  }

  /**
   * Create a subscription (Pro plan)
   * @param {Object} params - Subscription parameters
   * @returns {Promise<Object>} Subscription details
   */
  async createSubscription(params) {
    const { userId, priceId, customerEmail } = params;

    try {
      // Create or get customer
      const customer = await stripe.customers.create({
        email: customerEmail,
        metadata: { userId },
      });

      // Create subscription
      const subscription = await stripe.subscriptions.create({
        customer: customer.id,
        items: [{ price: priceId }],
        payment_behavior: 'default_incomplete',
        expand: ['latest_invoice.payment_intent'],
      });

      // Record in database
      await db.query(
        `INSERT INTO subscriptions (
          user_id, stripe_customer_id, stripe_subscription_id,
          status, plan_type, current_period_start, current_period_end
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [
          userId,
          customer.id,
          subscription.id,
          'incomplete',
          'pro',
          new Date(subscription.current_period_start * 1000),
          new Date(subscription.current_period_end * 1000),
        ]
      );

      return {
        subscriptionId: subscription.id,
        clientSecret: subscription.latest_invoice?.payment_intent?.client_secret,
      };
    } catch (error) {
      console.error('Subscription creation failed:', error);
      throw error;
    }
  }

  /**
   * Cancel subscription
   * @param {string} subscriptionId - Stripe subscription ID
   * @returns {Promise<Object>} Cancelled subscription
   */
  async cancelSubscription(subscriptionId) {
    try {
      const subscription = await stripe.subscriptions.cancel(subscriptionId);

      await db.query(
        `UPDATE subscriptions SET status = 'cancelled', updated_at = NOW()
         WHERE stripe_subscription_id = $1`,
        [subscriptionId]
      );

      return subscription;
    } catch (error) {
      console.error('Subscription cancellation failed:', error);
      throw error;
    }
  }

  /**
   * Get user's active subscription
   * @param {string} userId - User UUID
   * @returns {Promise<Object|null>} Active subscription
   */
  async getActiveSubscription(userId) {
    const result = await db.query(
      `SELECT * FROM subscriptions 
       WHERE user_id = $1 AND status IN ('active', 'trialing')
       ORDER BY created_at DESC LIMIT 1`,
      [userId]
    );
    return result.rows[0] || null;
  }

  /**
   * Create split payment
   * @param {Object} params - Split payment parameters
   * @returns {Promise<Object>} Split payment details
   */
  async createSplitPayment(params) {
    const { totalAmount, currency, participants, description } = params;

    const splitAmount = totalAmount / participants.length;

    // Create a group payment record
    const groupResult = await db.query(
      `INSERT INTO split_payments (
        total_amount, currency, participant_count, description, status
      ) VALUES ($1, $2, $3, $4, $5)
      RETURNING *`,
      [totalAmount, currency, participants.length, description, 'pending']
    );

    const groupPayment = groupResult.rows[0];

    // Create individual payment records
    for (const participant of participants) {
      await db.query(
        `INSERT INTO split_payment_participants (
          split_payment_id, user_id, amount, status
        ) VALUES ($1, $2, $3, $4)`,
        [groupPayment.id, participant.userId, splitAmount, 'pending']
      );
    }

    return groupPayment;
  }

  /**
   * Record participant payment in split
   * @param {string} splitPaymentId - Split payment UUID
   * @param {string} userId - User UUID
   * @param {string} paymentIntentId - Stripe payment intent ID
   * @returns {Promise<Object>} Updated participant record
   */
  async recordSplitPayment(splitPaymentId, userId, paymentIntentId) {
    await db.query(
      `UPDATE split_payment_participants 
       SET payment_intent_id = $1, status = 'paid', paid_at = NOW()
       WHERE split_payment_id = $2 AND user_id = $3`,
      [paymentIntentId, splitPaymentId, userId]
    );

    // Check if all participants paid
    const result = await db.query(
      `SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'paid' THEN 1 END) as paid
       FROM split_payment_participants 
       WHERE split_payment_id = $1`,
      [splitPaymentId]
    );

    const { total, paid } = result.rows[0];
    if (total === paid) {
      await db.query(
        `UPDATE split_payments SET status = 'completed', updated_at = NOW()
         WHERE id = $1`,
        [splitPaymentId]
      );
    }

    return result.rows[0];
  }
}

module.exports = new PaymentService();
