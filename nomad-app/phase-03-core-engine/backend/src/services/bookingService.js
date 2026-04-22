const axios = require('axios');
const config = require('../config');
const db = require('../config/database');

class BookingService {
  /**
   * Search activities on GetYourGuide
   * @param {string} city - City name
   * @param {Date} date - Activity date
   * @param {number} adults - Number of adults
   * @returns {Promise<Array>} Available activities
   */
  async searchActivities(city, date, adults = 1) {
    try {
      // Using GetYourGuide Affiliate API
      // In production, use real API key from config
      const response = await axios.get('https://travelers-api.getyourguide.com/search', {
        params: {
          q: city,
          date: date.toISOString().split('T')[0],
          adults,
          currency: 'USD',
        },
        headers: {
          'Authorization': `Bearer ${config.getYourGuide?.apiKey || 'demo'}`,
        },
        timeout: 10000,
      });

      return response.data.data?.activities || [];
    } catch (error) {
      console.error('GetYourGuide search failed:', error.message);
      // Return mock data for development
      return this._getMockActivities(city);
    }
  }

  /**
   * Create a booking
   * @param {Object} params - Booking parameters
   * @returns {Promise<Object>} Created booking
   */
  async createBooking(params) {
    const {
      userId,
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
    } = params;

    const result = await db.query(
      `INSERT INTO bookings (
        user_id, activity_id, activity_name, provider, 
        booking_date, adults, children, total_price, currency,
        contact_email, contact_phone, status
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
      RETURNING *`,
      [
        userId,
        activityId,
        activityName,
        provider,
        date,
        adults,
        children || 0,
        totalPrice,
        currency,
        contactEmail,
        contactPhone,
        'pending',
      ]
    );

    return result.rows[0];
  }

  /**
   * Get user's bookings
   * @param {string} userId - User UUID
   * @returns {Promise<Array>} User bookings
   */
  async getUserBookings(userId) {
    const result = await db.query(
      `SELECT * FROM bookings WHERE user_id = $1 ORDER BY booking_date DESC`,
      [userId]
    );
    return result.rows;
  }

  /**
   * Update booking status
   * @param {string} bookingId - Booking UUID
   * @param {string} status - New status
   * @returns {Promise<Object>} Updated booking
   */
  async updateBookingStatus(bookingId, status) {
    const result = await db.query(
      `UPDATE bookings SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
      [status, bookingId]
    );
    return result.rows[0];
  }

  /**
   * Cancel booking
   * @param {string} bookingId - Booking UUID
   * @returns {Promise<Object>} Cancelled booking
   */
  async cancelBooking(bookingId) {
    return this.updateBookingStatus(bookingId, 'cancelled');
  }

  _getMockActivities(city) {
    return [
      {
        id: 'mock-1',
        title: `${city} Walking Tour`,
        description: 'Discover the city with a local guide',
        price: 45,
        currency: 'USD',
        duration: '3 hours',
        rating: 4.8,
        reviews: 1240,
        image: 'https://example.com/tour1.jpg',
      },
      {
        id: 'mock-2',
        title: `${city} Food Experience`,
        description: 'Taste local cuisine at hidden gems',
        price: 75,
        currency: 'USD',
        duration: '4 hours',
        rating: 4.9,
        reviews: 856,
        image: 'https://example.com/tour2.jpg',
      },
      {
        id: 'mock-3',
        title: `${city} Museum Pass`,
        description: 'Skip-the-line access to top museums',
        price: 35,
        currency: 'USD',
        duration: '1 day',
        rating: 4.7,
        reviews: 2341,
        image: 'https://example.com/tour3.jpg',
      },
    ];
  }
}

module.exports = new BookingService();
