const { v4: uuidv4 } = require('uuid');

async function tripRoutes(fastify, options) {
  const { pg, jwt, redis } = fastify;

  // Auth middleware
  fastify.addHook('preHandler', async (request, reply) => {
    try {
      const token = request.headers.authorization?.replace('Bearer ', '');
      if (!token) {
        return reply.status(401).send({ error: 'No token provided' });
      }
      const decoded = jwt.verify(token, fastify.config.jwt.secret);
      request.user = decoded;
    } catch (err) {
      return reply.status(401).send({ error: 'Invalid token' });
    }
  });

  // Generate AI trip
  fastify.post('/generate', async (request, reply) => {
    const userId = request.user.userId;
    const {
      destination,
      country,
      start_date,
      end_date,
      budget_level,
      intensity,
      transport_mode,
      interests,
      cuisines,
      wake_up_time,
      sleep_time,
      travelers_count,
      special_requirements,
    } = request.body;

    try {
      // Create trip
      const tripResult = await pg.query(`
        INSERT INTO trips (
          user_id, title, description, destination, country,
          start_date, end_date, status, budget_level, intensity,
          transport_mode, interests, cuisines, wake_up_time, sleep_time,
          travelers_count, special_requirements, generation_progress
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
        RETURNING *
      `, [
        userId,
        `${destination} Adventure`,
        `AI-generated ${intensity} trip to ${destination}`,
        destination,
        country,
        start_date,
        end_date,
        'generating',
        budget_level || 'moderate',
        intensity || 'balanced',
        transport_mode || 'mixed',
        JSON.stringify(interests || []),
        JSON.stringify(cuisines || []),
        wake_up_time,
        sleep_time,
        travelers_count || 1,
        special_requirements,
        0,
      ]);

      const trip = tripResult.rows[0];
      const days = Math.ceil((new Date(end_date) - new Date(start_date)) / (1000 * 60 * 60 * 24)) + 1;

      // Generate days and activities (mock AI generation)
      const tripDays = [];
      for (let i = 0; i < days; i++) {
        const date = new Date(start_date);
        date.setDate(date.getDate() + i);

        const dayResult = await pg.query(`
          INSERT INTO trip_days (trip_id, day_number, date, theme)
          VALUES ($1, $2, $3, $4)
          RETURNING *
        `, [
          trip.id,
          i + 1,
          date.toISOString().split('T')[0],
          getDayTheme(i, days),
        ]);

        const day = dayResult.rows[0];
        const activities = generateActivities(i, destination, budget_level);

        for (const activity of activities) {
          await pg.query(`
            INSERT INTO trip_activities (
              trip_day_id, trip_id, title, description, category,
              duration_minutes, cost, currency, start_time
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
          `, [
            day.id,
            trip.id,
            activity.title,
            activity.description,
            activity.category,
            activity.duration,
            activity.cost,
            'USD',
            activity.startTime,
          ]);
        }

        tripDays.push({ ...day, activities });
      }

      // Update trip status
      await pg.query(`
        UPDATE trips SET status = 'active', generation_progress = 100, updated_at = CURRENT_TIMESTAMP
        WHERE id = $1
      `, [trip.id]);

      // Return full trip
      const fullTrip = await getFullTrip(pg, trip.id);

      return {
        success: true,
        data: fullTrip,
      };
    } catch (error) {
      fastify.log.error(error);
      return reply.status(500).send({
        success: false,
        error: 'Trip generation failed',
        details: error.message,
      });
    }
  });

  // Get user's trips
  fastify.get('/', async (request, reply) => {
    const userId = request.user.userId;

    try {
      const result = await pg.query(`
        SELECT 
          t.*,
          COUNT(DISTINCT td.id) as total_days,
          COUNT(DISTINCT ta.id) as total_activities,
          COUNT(DISTINCT CASE WHEN ta.completed THEN ta.id END) as completed_activities
        FROM trips t
        LEFT JOIN trip_days td ON td.trip_id = t.id
        LEFT JOIN trip_activities ta ON ta.trip_id = t.id
        WHERE t.user_id = $1
        GROUP BY t.id
        ORDER BY t.created_at DESC
      `, [userId]);

      return {
        success: true,
        data: result.rows,
      };
    } catch (error) {
      return reply.status(500).send({ error: error.message });
    }
  });

  // Get single trip with details
  fastify.get('/:id', async (request, reply) => {
    const { id } = request.params;
    const userId = request.user.userId;

    try {
      const trip = await getFullTrip(pg, id, userId);
      if (!trip) {
        return reply.status(404).send({ error: 'Trip not found' });
      }

      return {
        success: true,
        data: trip,
      };
    } catch (error) {
      return reply.status(500).send({ error: error.message });
    }
  });

  // Update activity status
  fastify.patch('/activities/:id', async (request, reply) => {
    const { id } = request.params;
    const { completed, skipped, notes } = request.body;
    const userId = request.user.userId;

    try {
      // Verify ownership
      const checkResult = await pg.query(`
        SELECT t.user_id FROM trip_activities ta
        JOIN trips t ON t.id = ta.trip_id
        WHERE ta.id = $1
      `, [id]);

      if (checkResult.rows.length === 0 || checkResult.rows[0].user_id !== userId) {
        return reply.status(403).send({ error: 'Not authorized' });
      }

      const updates = [];
      const values = [id];
      let paramIndex = 2;

      if (completed !== undefined) {
        updates.push(`completed = $${paramIndex++}`);
        values.push(completed);
      }
      if (skipped !== undefined) {
        updates.push(`skipped = $${paramIndex++}`);
        values.push(skipped);
      }
      if (notes !== undefined) {
        updates.push(`notes = $${paramIndex++}`);
        values.push(notes);
      }

      if (updates.length === 0) {
        return reply.status(400).send({ error: 'No fields to update' });
      }

      await pg.query(`
        UPDATE trip_activities SET ${updates.join(', ')} WHERE id = $1
      `, values);

      return {
        success: true,
        message: 'Activity updated',
      };
    } catch (error) {
      return reply.status(500).send({ error: error.message });
    }
  });

  // Delete trip
  fastify.delete('/:id', async (request, reply) => {
    const { id } = request.params;
    const userId = request.user.userId;

    try {
      const result = await pg.query(`
        DELETE FROM trips WHERE id = $1 AND user_id = $2
        RETURNING id
      `, [id, userId]);

      if (result.rows.length === 0) {
        return reply.status(404).send({ error: 'Trip not found' });
      }

      return {
        success: true,
        message: 'Trip deleted',
      };
    } catch (error) {
      return reply.status(500).send({ error: error.message });
    }
  });

  // Get cost breakdown
  fastify.get('/:id/costs', async (request, reply) => {
    const { id } = request.params;
    const userId = request.user.userId;

    try {
      const result = await pg.query(`
        SELECT 
          COALESCE(SUM(CASE WHEN category = 'rest' THEN cost ELSE 0 END), 0) as accommodation,
          COALESCE(SUM(CASE WHEN category = 'food' THEN cost ELSE 0 END), 0) as food,
          COALESCE(SUM(CASE WHEN category = 'transport' THEN cost ELSE 0 END), 0) as transport,
          COALESCE(SUM(CASE WHEN category = 'sightseeing' OR category = 'entertainment' THEN cost ELSE 0 END), 0) as activities,
          COALESCE(SUM(CASE WHEN category = 'shopping' THEN cost ELSE 0 END), 0) as shopping,
          COALESCE(SUM(cost), 0) as total
        FROM trip_activities ta
        JOIN trips t ON t.id = ta.trip_id
        WHERE ta.trip_id = $1 AND t.user_id = $2 AND ta.skipped = FALSE
      `, [id, userId]);

      const costs = result.rows[0];
      return {
        success: true,
        data: {
          accommodation: parseFloat(costs.accommodation),
          food: parseFloat(costs.food),
          transport: parseFloat(costs.transport),
          activities: parseFloat(costs.activities),
          shopping: parseFloat(costs.shopping),
          other: 0,
          total: parseFloat(costs.total),
          currency: 'USD',
        },
      };
    } catch (error) {
      return reply.status(500).send({ error: error.message });
    }
  });
}

// Helper functions
function getDayTheme(index, totalDays) {
  const themes = [
    'Arrival & Orientation',
    'City Highlights',
    'Hidden Gems',
    'Cultural Deep Dive',
    'Nature & Outdoors',
    'Food & Markets',
    'Museums & History',
    'Relaxation Day',
    'Adventure & Activities',
    'Farewell & Departure',
  ];
  if (index === 0) return 'Arrival & Orientation';
  if (index === totalDays - 1) return 'Farewell & Departure';
  return themes[index % themes.length];
}

function generateActivities(dayIndex, destination, budgetLevel) {
  const baseCost = budgetLevel === 'budget' ? 15 : budgetLevel === 'luxury' ? 60 : 30;
  const baseHour = 9;

  return [
    {
      title: dayIndex === 0 ? 'Check-in at hotel' : 'Morning exploration',
      description: dayIndex === 0 ? 'Get settled in your accommodation' : `Discover ${destination}'s morning attractions`,
      category: dayIndex === 0 ? 'rest' : 'sightseeing',
      duration: dayIndex === 0 ? 120 : 180,
      cost: dayIndex === 0 ? baseCost * 2 : baseCost,
      startTime: `${baseHour}:00`,
    },
    {
      title: 'Lunch at local restaurant',
      description: 'Experience local cuisine',
      category: 'food',
      duration: 90,
      cost: baseCost * 0.8,
      startTime: `${baseHour + 4}:00`,
    },
    {
      title: `Afternoon in ${destination}`,
      description: 'Explore the area',
      category: 'sightseeing',
      duration: 180,
      cost: baseCost * 1.2,
      startTime: `${baseHour + 6}:00`,
    },
    {
      title: 'Dinner experience',
      description: 'Evening dining',
      category: 'food',
      duration: 120,
      cost: baseCost * 1.5,
      startTime: `${baseHour + 10}:00`,
    },
  ];
}

async function getFullTrip(pg, tripId, userId = null) {
  const tripQuery = userId
    ? 'SELECT * FROM trips WHERE id = $1 AND user_id = $2'
    : 'SELECT * FROM trips WHERE id = $1';
  const tripParams = userId ? [tripId, userId] : [tripId];

  const tripResult = await pg.query(tripQuery, tripParams);
  if (tripResult.rows.length === 0) return null;

  const trip = tripResult.rows[0];

  // Parse JSON fields
  trip.interests = JSON.parse(trip.interests || '[]');
  trip.cuisines = JSON.parse(trip.cuisines || '[]');

  // Get days
  const daysResult = await pg.query(`
    SELECT * FROM trip_days WHERE trip_id = $1 ORDER BY day_number
  `, [tripId]);

  const days = [];
  for (const day of daysResult.rows) {
    const activitiesResult = await pg.query(`
      SELECT * FROM trip_activities WHERE trip_day_id = $1 ORDER BY start_time
    `, [day.id]);

    days.push({
      ...day,
      activities: activitiesResult.rows,
    });
  }

  trip.days = days;
  return trip;
}

module.exports = tripRoutes;
