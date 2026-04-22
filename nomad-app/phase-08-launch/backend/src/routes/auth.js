const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const config = require('../config');
const db = require('../config/database');

const SALT_ROUNDS = 12;
const ACCESS_TOKEN_EXPIRY = '15m';
const REFRESH_TOKEN_EXPIRY = '7d';

function generateTokens(userId) {
  const accessToken = jwt.sign({ userId, type: 'access' }, config.jwt.secret, { expiresIn: ACCESS_TOKEN_EXPIRY });
  const refreshToken = jwt.sign({ userId, type: 'refresh', jti: uuidv4() }, config.jwt.secret, { expiresIn: REFRESH_TOKEN_EXPIRY });
  return { accessToken, refreshToken };
}

async function authRoutes(fastify, options) {
  // Register
  fastify.post('/register', {
    schema: {
      body: {
        type: 'object',
        required: ['email', 'password'],
        properties: {
          email: { type: 'string', format: 'email' },
          password: { type: 'string', minLength: 8 },
          name: { type: 'string' },
          native_language: { type: 'string', default: 'ru' },
        },
      },
    },
  }, async (request, reply) => {
    const { email, password, name, native_language } = request.body;

    const existing = await db.query('SELECT id FROM users WHERE email = $1', [email.toLowerCase()]);
    if (existing.rows.length > 0) {
      reply.code(409);
      throw new Error('Email already registered');
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
    const verificationToken = uuidv4();

    const result = await db.query(
      `INSERT INTO users (email, password_hash, name, native_language, email_verification_token)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, email, name, native_language, email_verified, created_at`,
      [email.toLowerCase(), passwordHash, name || null, native_language || 'ru', verificationToken]
    );

    const user = result.rows[0];
    const { accessToken, refreshToken } = generateTokens(user.id);

    // Store refresh token hash
    const refreshHash = await bcrypt.hash(refreshToken, SALT_ROUNDS);
    await db.query(
      `INSERT INTO user_sessions (user_id, refresh_token_hash, device_info, expires_at)
       VALUES ($1, $2, $3, NOW() + INTERVAL '7 days')`,
      [user.id, refreshHash, JSON.stringify(request.headers['user-agent'] || {})]
    );

    reply.code(201);
    return {
      success: true,
      user: { id: user.id, email: user.email, name: user.name, native_language: user.native_language },
      tokens: { accessToken, refreshToken },
    };
  });

  // Login
  fastify.post('/login', async (request, reply) => {
    const { email, password } = request.body;

    const result = await db.query(
      'SELECT id, email, password_hash, name, native_language, email_verified FROM users WHERE email = $1',
      [email.toLowerCase()]
    );

    if (result.rows.length === 0) {
      reply.code(401);
      throw new Error('Invalid credentials');
    }

    const user = result.rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      reply.code(401);
      throw new Error('Invalid credentials');
    }

    const { accessToken, refreshToken } = generateTokens(user.id);

    const refreshHash = await bcrypt.hash(refreshToken, SALT_ROUNDS);
    await db.query(
      `INSERT INTO user_sessions (user_id, refresh_token_hash, device_info, expires_at)
       VALUES ($1, $2, $3, NOW() + INTERVAL '7 days')`,
      [user.id, refreshHash, JSON.stringify(request.headers['user-agent'] || {})]
    );

    return {
      success: true,
      user: { id: user.id, email: user.email, name: user.name, native_language: user.native_language },
      tokens: { accessToken, refreshToken },
    };
  });

  // Refresh token
  fastify.post('/refresh', async (request, reply) => {
    const { refreshToken } = request.body;
    if (!refreshToken) {
      reply.code(400);
      throw new Error('Refresh token required');
    }

    let decoded;
    try {
      decoded = jwt.verify(refreshToken, config.jwt.secret);
    } catch (err) {
      reply.code(401);
      throw new Error('Invalid refresh token');
    }

    if (decoded.type !== 'refresh') {
      reply.code(401);
      throw new Error('Invalid token type');
    }

    // Check if token hash exists and is not revoked
    const hashResult = await db.query(
      `SELECT id FROM user_sessions 
       WHERE user_id = $1 AND revoked_at IS NULL AND expires_at > NOW()`,
      [decoded.userId]
    );

    if (hashResult.rows.length === 0) {
      reply.code(401);
      throw new Error('Session expired');
    }

    // Verify one of the hashes matches
    let validSession = false;
    for (const row of hashResult.rows) {
      const sessionResult = await db.query('SELECT refresh_token_hash FROM user_sessions WHERE id = $1', [row.id]);
      if (sessionResult.rows.length > 0) {
        const match = await bcrypt.compare(refreshToken, sessionResult.rows[0].refresh_token_hash);
        if (match) {
          validSession = true;
          break;
        }
      }
    }

    if (!validSession) {
      reply.code(401);
      throw new Error('Invalid session');
    }

    const tokens = generateTokens(decoded.userId);
    return { success: true, tokens };
  });

  // Logout
  fastify.post('/logout', async (request, reply) => {
    const authHeader = request.headers.authorization;
    if (authHeader) {
      const token = authHeader.replace('Bearer ', '');
      try {
        const decoded = jwt.verify(token, config.jwt.secret);
        // Revoke all sessions for user (or specific session)
        await db.query(
          'UPDATE user_sessions SET revoked_at = NOW() WHERE user_id = $1',
          [decoded.userId]
        );
      } catch (e) {
        // Ignore invalid token on logout
      }
    }
    return { success: true, message: 'Logged out' };
  });

  // Get current user
  fastify.get('/me', async (request, reply) => {
    const userId = request.user.userId;
    const result = await db.query(
      'SELECT id, email, name, avatar_url, native_language, email_verified, created_at FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      reply.code(404);
      throw new Error('User not found');
    }

    return { success: true, user: result.rows[0] };
  });

  // Update profile
  fastify.patch('/me', async (request, reply) => {
    const userId = request.user.userId;
    const { name, native_language, avatar_url } = request.body;

    const result = await db.query(
      `UPDATE users 
       SET name = COALESCE($1, name),
           native_language = COALESCE($2, native_language),
           avatar_url = COALESCE($3, avatar_url),
           updated_at = NOW()
       WHERE id = $4
       RETURNING id, email, name, avatar_url, native_language, email_verified`,
      [name, native_language, avatar_url, userId]
    );

    return { success: true, user: result.rows[0] };
  });

  // Request password reset
  fastify.post('/password-reset-request', async (request, reply) => {
    const { email } = request.body;
    const token = uuidv4();

    await db.query(
      `UPDATE users 
       SET password_reset_token = $1, password_reset_expires = NOW() + INTERVAL '1 hour'
       WHERE email = $2`,
      [token, email.toLowerCase()]
    );

    // In production, send email here
    return { success: true, message: 'If email exists, reset link sent', token };
  });

  // Reset password
  fastify.post('/password-reset', async (request, reply) => {
    const { token, password } = request.body;
    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    const result = await db.query(
      `UPDATE users 
       SET password_hash = $1,
           password_reset_token = NULL,
           password_reset_expires = NULL,
           updated_at = NOW()
       WHERE password_reset_token = $2 AND password_reset_expires > NOW()
       RETURNING id`,
      [passwordHash, token]
    );

    if (result.rows.length === 0) {
      reply.code(400);
      throw new Error('Invalid or expired token');
    }

    return { success: true, message: 'Password updated' };
  });
}

module.exports = authRoutes;
