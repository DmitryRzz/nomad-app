import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  static const String baseUrl = 'http://localhost:3000';
  
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, dynamic>?> createPaymentIntent(double amount, String currency, {Map<String, dynamic>? metadata}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/intent'),
        headers: headers,
        body: json.encode({
          'amount': amount,
          'currency': currency,
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error creating payment intent: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createSubscription(String priceId, String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/subscription'),
        headers: headers,
        body: json.encode({
          'priceId': priceId,
          'customerEmail': email,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error creating subscription: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getActiveSubscription() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments/subscription'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching subscription: $e');
      return null;
    }
  }

  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/payments/subscription/$subscriptionId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error cancelling subscription: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> createSplitPayment(double totalAmount, String currency, List<Map<String, dynamic>> participants, String description) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/split'),
        headers: headers,
        body: json.encode({
          'totalAmount': totalAmount,
          'currency': currency,
          'participants': participants,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error creating split payment: $e');
      return null;
    }
  }

  Future<List<dynamic>> getPaymentHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments/history'),
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
      print('Error fetching payment history: $e');
      return [];
    }
  }
}