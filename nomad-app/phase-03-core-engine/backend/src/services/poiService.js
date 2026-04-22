const db = require('../config/database');

class POIService {
  /**
   * Find POIs near a location
   * @param {number} latitude - User latitude
   * @param {number} longitude - User longitude
   * @param {number} radius - Radius in meters (default 500)
   * @param {string} category - Filter by category (optional)
   * @param {Array<string>} interests - User interests for relevance scoring (optional)
   * @param {number} limit - Max results (default 20)
   * @returns {Promise<Array>} Nearby POIs with distance
   */
  async findNearby(latitude, longitude, radius = 500, category = null, interests = [], limit = 20) {
    // Use PostGIS for spatial query
    let query = `
      SELECT 
        p.*,
        ST_Distance(
          ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography,
          ST_SetSRID(ST_MakePoint(p.longitude, p.latitude), 4326)::geography
        ) as distance_meters
      FROM poi p
      WHERE ST_DWithin(
        ST_SetSRID(ST_MakePoint($2, $1), 4326)::geography,
        ST_SetSRID(ST_MakePoint(p.longitude, p.latitude), 4326)::geography,
        $3
      )
    `;
    
    const params = [latitude, longitude, radius];
    let paramIndex = 4;
    
    if (category) {
      query += ` AND p.category = $${paramIndex}`;
      params.push(category);
      paramIndex++;
    }
    
    query += ` ORDER BY distance_meters ASC`;
    
    if (limit) {
      query += ` LIMIT $${paramIndex}`;
      params.push(limit);
    }
    
    const result = await db.query(query, params);
    
    // Add relevance score based on interests
    return result.rows.map(poi => {
      let relevance = 0;
      if (interests.length > 0 && poi.tags) {
        relevance = interests.filter(i => poi.tags.includes(i)).length;
      }
      return {
        ...poi,
        relevance_score: relevance,
      };
    }).sort((a, b) => b.relevance_score - a.relevance_score || a.distance_meters - b.distance_meters);
  }

  /**
   * Get POI by ID
   * @param {string} id - POI UUID
   * @returns {Promise<Object>} POI details
   */
  async getById(id) {
    const result = await db.query(
      `SELECT * FROM poi WHERE id = $1`,
      [id]
    );
    return result.rows[0] || null;
  }

  /**
   * Get POIs by category in a city
   * @param {string} city - City name
   * @param {string} category - Category (optional)
   * @param {number} limit - Max results
   * @returns {Promise<Array>} POIs
   */
  async getByCity(city, category = null, limit = 50) {
    let query = `SELECT * FROM poi WHERE city ILIKE $1`;
    const params = [city];
    
    if (category) {
      query += ` AND category = $2`;
      params.push(category);
    }
    
    query += ` ORDER BY rating DESC NULLS LAST LIMIT $${params.length + 1}`;
    params.push(limit);
    
    const result = await db.query(query, params);
    return result.rows;
  }
}

module.exports = new POIService();
