const admin = require('firebase-admin');
const db = require('../config/database');

// Initialize Firebase Admin if service account is available
let firebaseInitialized = false;
try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    firebaseInitialized = true;
  }
} catch (err) {
  console.warn('Firebase Admin not initialized:', err.message);
}

async function pushRoutes(fastify, options) {
  // Register FCM token
  fastify.post('/token', async (request, reply) => {
    const userId = request.user.userId;
    const { token, deviceType, deviceId, appVersion, locale } = request.body;

    await db.query(
      `INSERT INTO fcm_tokens (user_id, token, device_type, device_id, app_version, locale, last_used_at)
       VALUES ($1, $2, $3, $4, $5, $6, NOW())
       ON CONFLICT (user_id, device_id)
       DO UPDATE SET token = $2, device_type = $3, app_version = $5, locale = $6, last_used_at = NOW(), is_active = TRUE`,
      [userId, token, deviceType, deviceId, appVersion, locale]
    );

    return { success: true, message: 'Token registered' };
  });

  // Remove FCM token (on logout or uninstall)
  fastify.delete('/token', async (request, reply) => {
    const userId = request.user.userId;
    const { deviceId } = request.body;

    await db.query(
      'UPDATE fcm_tokens SET is_active = FALSE WHERE user_id = $1 AND device_id = $2',
      [userId, deviceId]
    );

    return { success: true, message: 'Token removed' };
  });

  // Get notifications
  fastify.get('/notifications', async (request, reply) => {
    const userId = request.user.userId;
    const { page = 1, limit = 20 } = request.query;
    const offset = (page - 1) * limit;

    const result = await db.query(
      `SELECT id, title, body, type, data, is_read, sent_at, created_at
       FROM notifications
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    const countResult = await db.query(
      'SELECT COUNT(*) FROM notifications WHERE user_id = $1',
      [userId]
    );

    const unreadResult = await db.query(
      'SELECT COUNT(*) FROM notifications WHERE user_id = $1 AND is_read = FALSE',
      [userId]
    );

    return {
      success: true,
      notifications: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: parseInt(countResult.rows[0].count),
        unread: parseInt(unreadResult.rows[0].count),
      },
    };
  });

  // Mark notification as read
  fastify.patch('/notifications/:id/read', async (request, reply) => {
    const userId = request.user.userId;
    const { id } = request.params;

    await db.query(
      'UPDATE notifications SET is_read = TRUE, read_at = NOW() WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    return { success: true };
  });

  // Mark all as read
  fastify.post('/notifications/read-all', async (request, reply) => {
    const userId = request.user.userId;

    await db.query(
      'UPDATE notifications SET is_read = TRUE, read_at = NOW() WHERE user_id = $1 AND is_read = FALSE',
      [userId]
    );

    return { success: true };
  });

  // Send test notification (admin only in production)
  fastify.post('/send', async (request, reply) => {
    if (!firebaseInitialized) {
      reply.code(503);
      throw new Error('Push notifications not configured');
    }

    const { userId, title, body, data } = request.body;

    const tokensResult = await db.query(
      'SELECT token FROM fcm_tokens WHERE user_id = $1 AND is_active = TRUE',
      [userId]
    );

    if (tokensResult.rows.length === 0) {
      return { success: false, message: 'No active tokens for user' };
    }

    const tokens = tokensResult.rows.map(r => r.token);

    const message = {
      notification: { title, body },
      data: data || {},
      tokens,
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);

      // Store in notifications table
      await db.query(
        `INSERT INTO notifications (user_id, title, body, type, data, sent_at)
         VALUES ($1, $2, $3, $4, $5, NOW())`,
        [userId, title, body, data?.type || 'general', JSON.stringify(data || {})]
      );

      return {
        success: true,
        sent: response.successCount,
        failed: response.failureCount,
      };
    } catch (err) {
      reply.code(500);
      throw new Error(`Failed to send: ${err.message}`);
    }
  });
}

module.exports = pushRoutes;
