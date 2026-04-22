import 'dart:convert';
import 'package:http/http.dart' as http;

class BookingService {
  static const String baseUrl = 'http://localhost:3000';
  
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<List<dynamic>> searchActivities(String city, {DateTime? date, int adults = 1}) async {
    try {
      final queryParams = {
        'city': city,
        'adults': adults.toString(),
        if (date != null) 'date': date.toIso8601String(),
      };

      final response = await http.get(
        Uri.parse('$baseUrl/bookings/search').replace(queryParameters: queryParams),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] as List;
        }
      }
      return [];
    } catch (e) {
      print('Error searching activities: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: headers,
        body: json.encode(bookingData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error creating booking: $e');
      return null;
    }
  }

  Future<List<dynamic>> getUserBookings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] as List;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }
}