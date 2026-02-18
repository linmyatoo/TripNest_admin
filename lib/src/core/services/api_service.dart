import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_storage.dart';

class ApiService {
  static const String baseUrl = 'https://naylinhtet.me/api';

  // Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final body = {
        'email': email,
        'password': password,
      };
      if (name != null && name.isNotEmpty) {
        body['name'] = name;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'token': data['token'],
          'userId': data['userId'],
          'email': data['email'],
          'expiresIn': data['expiresIn'],
          'message': data['message'] ?? 'Registration successful',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'token': data['token'],
          'userId': data['userId'],
          'email': data['email'],
          'expiresIn': data['expiresIn'],
          'message': data['message'] ?? 'Login successful',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Invalid email or password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Logout user
  Future<Map<String, dynamic>> logout() async {
    try {
      final token = AuthStorage.getAuthHeader();

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await AuthStorage.clearAuth();
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Logout failed',
        };
      }
    } catch (e) {
      await AuthStorage.clearAuth();
      return {
        'success': true,
        'message': 'Logged out locally',
      };
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final token = AuthStorage.getAuthHeader();

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password changed successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = AuthStorage.getAuthHeader();

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get organizer profile
  Future<Map<String, dynamic>> getOrganizerProfile() async {
    try {
      final token = AuthStorage.getAuthHeader();

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/organizers/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch organizer profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Create/Update organizer profile
  Future<Map<String, dynamic>> createOrganizerProfile({
    String? organizationName,
    String? contactNumber,
    String? address,
  }) async {
    try {
      final token = AuthStorage.getAuthHeader();

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final body = <String, dynamic>{};
      if (organizationName != null && organizationName.isNotEmpty) {
        body['organizationName'] = organizationName;
      }
      if (contactNumber != null && contactNumber.isNotEmpty) {
        body['contactNumber'] = contactNumber;
      }
      if (address != null && address.isNotEmpty) {
        body['address'] = address;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/organizers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to save organizer profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Forgot password - sends reset link to email
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ??
              'If this email exists, a reset link has been sent',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to send reset link',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get dashboard revenue totals
  Future<Map<String, dynamic>> getDashboardRevenue() async {
    try {
      final token = AuthStorage.getAuthHeader();

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/revenue'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      print('Dashboard revenue status: ${response.statusCode}');
      print('Dashboard revenue body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'organizer': data['organizer'],
          'totalRevenue': (data['totalRevenue'] ?? 0).toDouble(),
          'totalBookings': data['totalBookings'] ?? 0,
          'totalTickets': data['totalTickets'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch revenue',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get dashboard events (event revenue breakdown)
  Future<Map<String, dynamic>> getDashboardEvents() async {
    try {
      final token = AuthStorage.getAuthHeader();

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/events'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      print('Dashboard events status: ${response.statusCode}');
      print('Dashboard events body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'organizer': data['organizer'],
          'events': data['events'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch events',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get event by ID
  Future<Map<String, dynamic>> getEventById(String eventId) async {
    try {
      final token = AuthStorage.getAuthHeader();

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'event': data,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch event',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get all my events (for organizer)
  Future<Map<String, dynamic>> getMyEvents() async {
    try {
      final token = AuthStorage.getAuthHeader();

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/events'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      print('My events status: ${response.statusCode}');
      print('My events body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = data is List ? data : (data['events'] ?? data);
        return {
          'success': true,
          'events': events is List ? events : [],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch events',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Create a new event with file uploads
  Future<Map<String, dynamic>> createEvent({
    required String title,
    String? description,
    required String date,
    required String location,
    required int capacity,
    required double price,
    String? mood,
    List<File>? images,
  }) async {
    try {
      final token = AuthStorage.getAuthHeader();

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/events'),
      );

      request.headers['Authorization'] = token;

      request.fields['title'] = title;
      request.fields['date'] = date;
      request.fields['location'] = location;
      request.fields['capacity'] = capacity.toString();
      request.fields['price'] = price.toString();

      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      if (mood != null && mood.isNotEmpty) {
        request.fields['mood'] = mood;
      }

      if (images != null && images.isNotEmpty) {
        for (final file in images) {
          final multipartFile = await http.MultipartFile.fromPath(
            'images',
            file.path,
          );
          request.files.add(multipartFile);
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Create event status: ${response.statusCode}');
      print('Create event body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'event': data,
          'message': 'Event created successfully',
        };
      } else {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': false,
            'message': data['error'] ?? 'Failed to create event',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Server error (${response.statusCode})',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update an event
  Future<Map<String, dynamic>> updateEvent({
    required String eventId,
    String? title,
    String? description,
    String? date,
    String? location,
    int? capacity,
    double? price,
    String? mood,
  }) async {
    try {
      final token = AuthStorage.getAuthHeader();

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (date != null) body['date'] = date;
      if (location != null) body['location'] = location;
      if (capacity != null) body['capacity'] = capacity;
      if (price != null) body['price'] = price;
      if (mood != null) body['mood'] = mood;

      final response = await http.patch(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode(body),
      );

      print('Update event status: ${response.statusCode}');
      print('Update event body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'event': data,
          'message': 'Event updated successfully',
        };
      } else {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': false,
            'message': data['error'] ?? 'Failed to update event',
          };
        } catch (_) {
          return {
            'success': false,
            'message': 'Server error (${response.statusCode})',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get reviews for an event
  Future<Map<String, dynamic>> getEventReviews(String eventId) async {
    try {
      final token = AuthStorage.getAuthHeader();

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/reviews/event/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reviews': data is List ? data : [],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch reviews',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get sentiment summary for an event
  // GET /api/sentiment/organizer/events/:eventId/summary
  Future<Map<String, dynamic>> getEventSentimentSummary(String eventId) async {
    try {
      final token = AuthStorage.getAuthHeader();

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/sentiment/organizer/events/$eventId/summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch sentiment summary',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get sentiment results for each review of an event
  // GET /api/sentiment/organizer/events/:eventId/reviews
  Future<Map<String, dynamic>> getEventSentimentReviews(String eventId) async {
    try {
      final token = AuthStorage.getAuthHeader();

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/sentiment/organizer/events/$eventId/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          // Exposes the sentiments array: [ { reviewId, label, score,
          // class, negativeSummary }, ... ]
          'sentiments': data['sentiments'] ?? [],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch sentiment reviews',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get all chat rooms
  Future<Map<String, dynamic>> getChatRooms() async {
    try {
      final token = AuthStorage.getAuthHeader();
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/chat/rooms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'rooms': data['rooms'] ?? [],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch chat rooms',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
