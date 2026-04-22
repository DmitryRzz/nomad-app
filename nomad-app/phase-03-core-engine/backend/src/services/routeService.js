const db = require('../config/database');
const aiService = require('./aiService');

class RouteService {
  /**
   * Create a new route for a user
   * @param {Object} params - Route creation params
   * @param {string} params.userId - User UUID
   * @param {string} params.city - Target city
   * @param {string} params.country - Country
   * @param {Object} params.preferences - User preferences
   * @returns {Promise<Object>} Created route
   */
  async createRoute(params) {
    const { userId, city, country, preferences = {} } = params;

    // 1. Fetch user preferences
    const userPrefs = await this.getUserPreferences(userId);
    const mergedPrefs = { ...userPrefs, ...preferences };

    // 2. Fetch weather data (mock for now, integrate real API later)
    const weather = await this.getWeather(city);

    // 3. Generate route with AI
    const aiRoute = await aiService.generateRoute({
      city,
      country,
      interests: mergedPrefs.interests || [],
      budgetLevel: mergedPrefs.budgetLevel || 3,
      pace: mergedPrefs.pace || 'balanced',
      weather,
      numStops: 5,
    });

    // 4. Save route to database
    const routeResult = await db.query(
      `INSERT INTO routes (user_id, title, city, country, status, estimated_duration_hours)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        userId,
        aiRoute.title,
        city,
        country,
        'active',
        aiRoute.stops.reduce((sum, stop) => sum + (stop.duration_minutes || 60), 0) / 60,
      ]
    );

    const route = routeResult.rows[0];

    // 5. Save stops
    for (let i = 0; i < aiRoute.stops.length; i++) {
      const stop = aiRoute.stops[i];
      
      // Try to find or create POI
      let poiId = await this.findOrCreatePOI(stop, city, country);

      await db.query(
        `INSERT INTO route_stops (route_id, poi_id, sequence_number, planned_time, duration_minutes, notes)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [
          route.id,
          poiId,
          i + 1,
          stop.time ? `${route.start_date || new Date().toISOString().split('T')[0]}T${stop.time}` : null,
          stop.duration_minutes || 60,
          stop.reason,
        ]
      );
    }

    // 6. Return full route with stops
    return this.getRouteById(route.id);
  }

  /**
   * Get route by ID with all stops
   * @param {string} routeId - Route UUID
   * @returns {Promise<Object>} Route with stops
   */
  async getRouteById(routeId) {
    const routeResult = await db.query(
      `SELECT * FROM routes WHERE id = $1`,
      [routeId]
    );

    if (routeResult.rows.length === 0) {
      throw new Error('Route not found');
    }

    const route = routeResult.rows[0];

    const stopsResult = await db.query(
      `SELECT rs.*, p.name as poi_name, p.category, p.description, p.latitude, p.longitude, 
              p.address, p.indoor, p.price_level, p.rating
       FROM route_stops rs
       JOIN poi p ON rs.poi_id = p.id
       WHERE rs.route_id = $1
       ORDER BY rs.sequence_number`,
      [routeId]
    );

    return {
      ...route,
      stops: stopsResult.rows,
    };
  }

  /**
   * Get all routes for a user
   * @param {string} userId - User UUID
   * @returns {Promise<Array>} User routes
   */
  async getUserRoutes(userId) {
    const result = await db.query(
      `SELECT * FROM routes WHERE user_id = $1 ORDER BY created_at DESC`,
      [userId]
    );
    return result.rows;
  }

  /**
   * Update route stop status
   * @param {string} stopId - Stop UUID
   * @param {Object} updates - Updates (visited, skipped, notes)
   * @returns {Promise<Object>} Updated stop
   */
  async updateStop(stopId, updates) {
    const { visited, skipped, notes } = updates;
    
    const result = await db.query(
      `UPDATE route_stops 
       SET visited = COALESCE($1, visited), 
           skipped = COALESCE($2, skipped), 
           notes = COALESCE($3, notes),
           updated_at = NOW()
       WHERE id = $4
       RETURNING *`,
      [visited, skipped, notes, stopId]
    );

    return result.rows[0];
  }

  /**
   * Delete a route
   * @param {string} routeId - Route UUID
   * @returns {Promise<boolean>} Success
   */
  async deleteRoute(routeId) {
    await db.query(`DELETE FROM routes WHERE id = $1`, [routeId]);
    return true;
  }

  /**
   * Get user preferences
   * @param {string} userId - User UUID
   * @returns {Promise<Object>} User preferences
   */
  async getUserPreferences(userId) {
    const result = await db.query(
      `SELECT * FROM user_preferences WHERE user_id = $1`,
      [userId]
    );
    return result.rows[0] || {};
  }

  /**
   * Find or create POI
   * @param {Object} poiData - POI data from AI
   * @param {string} city - City name
   * @param {string} country - Country name
   * @returns {Promise<string>} POI UUID
   */
  async findOrCreatePOI(poiData, city, country) {
    // Try to find existing POI by name and city
    const existing = await db.query(
      `SELECT id FROM poi WHERE name ILIKE $1 AND city ILIKE $2 LIMIT 1`,
      [poiData.name, city]
    );

    if (existing.rows.length > 0) {
      return existing.rows[0].id;
    }

    // Create new POI
    const result = await db.query(
      `INSERT INTO poi (name, description, category, subcategory, latitude, longitude, 
                        address, city, country, indoor, price_level, must_see, source)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, 'ai_generated')
       RETURNING id`,
      [
        poiData.name,
        poiData.description,
        poiData.category || 'other',
        null,
        poiData.latitude || 0,
        poiData.longitude || 0,
        poiData.address || '',
        city,
        country,
        poiData.indoor || false,
        poiData.price_level || 3,
        poiData.must_see || false,
      ]
    );

    return result.rows[0].id;
  }

  /**
   * Get weather data for a city
   * @param {string} city - City name
   * @returns {Promise<Object>} Weather data
   */
  async getWeather(city) {
    // Mock weather data - integrate with real API later
    return {
      condition: 'clear',
      temperature: 22,
      humidity: 60,
      windSpeed: 10,
      precipitation: 0,
      forecast: 'Sunny with light clouds',
    };
  }
}

module.exports = new RouteService();
