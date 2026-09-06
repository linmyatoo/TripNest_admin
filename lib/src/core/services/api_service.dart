import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_storage.dart';
import 'security_service.dart';
import 'session.dart';

class ApiService {
  /// [credentialClient] serves the endpoints that must NOT go through
  /// [apiClient]: there, a 401 means "wrong password", not "expired session",
  /// and routing them through the session-aware client would evict a valid
  /// login. Injectable so tests can supply a `MockClient`.
  ApiService({http.Client? credentialClient})
      : _credentialClient = credentialClient ?? http.Client();

  final http.Client _credentialClient;

  static const String baseUrl = ApiConfig.baseUrl;

  /// Log a request outcome without ever emitting the response body, which
  /// carries revenue figures, tokens, and other data that must not reach
  /// device logs. Debug builds only.
  static void _logStatus(String label, http.Response response) {
    if (kDebugMode) {
      debugPrint('$label: ${response.statusCode}');
    }
  }

  /// Decode a JSON object body, tolerating non-JSON error pages. nginx can
  /// answer with HTML (502) or an empty body (413), which would otherwise
  /// make `jsonDecode` throw and surface as a bogus "Network error".
  static Map<String, dynamic> _decodeOrEmpty(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  /// Decode a collection endpoint that may answer either with a bare JSON
  /// array or with an object wrapping that array under [key].
  ///
  /// [_decodeOrEmpty] cannot serve these: it is typed `Map<String, dynamic>`,
  /// so testing its result with `is List` is dead code that always takes the
  /// empty branch — which is exactly how the reviews list came to render as
  /// permanently empty.
  static List<dynamic> _decodeListOrEmpty(http.Response response, String key) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      if (decoded is Map<String, dynamic>) {
        final nested = decoded[key];
        if (nested is List) return nested;
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

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

      final response = await _credentialClient.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = _decodeOrEmpty(response);

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
      final response = await _credentialClient.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = _decodeOrEmpty(response);

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

  // Logout user.
  //
  // Local credentials are destroyed unconditionally. Revoking the session
  // server-side is best effort: if that call returns 401, 502, or anything
  // else, the user must still end up logged out on this device.
  //
  // This is the deliberate logout path, so it also resets the security
  // toggles. `AuthStorage.clearAuth` deliberately does not, because it also
  // runs on a transient 401 where wiping the user's preferences would be
  // surprising.
  Future<Map<String, dynamic>> logout() async {
    final token = AuthStorage.getAuthHeader();

    if (token == null) {
      await _clearLocalSession();
      return {
        'success': true,
        'message': 'Logged out locally',
      };
    }

    try {
      final response = await _credentialClient.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      _logStatus('Logout', response);

      final data = _decodeOrEmpty(response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      }
      return {
        'success': false,
        'message': data['message'] ??
            'Server logout failed (${response.statusCode}); '
                'logged out on this device',
      };
    } catch (e) {
      return {
        'success': true,
        'message': 'Logged out locally',
      };
    } finally {
      await _clearLocalSession();
    }
  }

  /// Tear down everything this device holds for the signed-in organizer.
  ///
  /// Best effort: a failure to reach SharedPreferences must not stop the
  /// caller from navigating away from the authenticated UI.
  static Future<void> _clearLocalSession() async {
    try {
      await AuthStorage.clearAuth();
      await SecurityService.clearAllSettings();
    } catch (e) {
      debugPrint('Failed to fully clear local session: $e');
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

      final response = await _credentialClient.post(
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

      final data = _decodeOrEmpty(response);

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

      final response = await apiClient.get(
        Uri.parse('$baseUrl/profile/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      final data = _decodeOrEmpty(response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch profile',
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

      final response = await apiClient.get(
        Uri.parse('$baseUrl/organizers/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      final data = _decodeOrEmpty(response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': data['error'] ?? 'Failed to fetch organizer profile',
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

      final response = await apiClient.post(
        Uri.parse('$baseUrl/organizers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode(body),
      );

      final data = _decodeOrEmpty(response);

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

  // Update an existing organizer profile
  Future<Map<String, dynamic>> updateOrganizerProfile({
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

      final response = await apiClient.patch(
        Uri.parse('$baseUrl/organizers/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode(body),
      );

      final data = _decodeOrEmpty(response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to update organizer profile',
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

      final data = _decodeOrEmpty(response);

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

      final response = await apiClient.get(
        Uri.parse('$baseUrl/dashboard/revenue'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      _logStatus('Dashboard revenue', response);

      final data = _decodeOrEmpty(response);

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

      final response = await apiClient.get(
        Uri.parse('$baseUrl/dashboard/events'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      _logStatus('Dashboard events', response);

      final data = _decodeOrEmpty(response);

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

      final response = await apiClient.get(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final data = _decodeOrEmpty(response);
        return {
          'success': true,
          'event': data,
        };
      } else {
        final data = _decodeOrEmpty(response);
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

      final response = await apiClient.get(
        Uri.parse('$baseUrl/events/mine'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      _logStatus('My events', response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'events': _decodeListOrEmpty(response, 'events'),
        };
      } else {
        final data = _decodeOrEmpty(response);
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

      final streamedResponse = await apiClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      _logStatus('Create event', response);

      if (response.statusCode == 201) {
        final data = _decodeOrEmpty(response);
        return {
          'success': true,
          'event': data,
          'message': 'Event created successfully',
        };
      } else {
        return {
          'success': false,
          'message': _decodeOrEmpty(response)['error'] ??
              'Failed to create event (${response.statusCode})',
        };
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

      final response = await apiClient.patch(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode(body),
      );

      _logStatus('Update event', response);

      if (response.statusCode == 200) {
        final data = _decodeOrEmpty(response);
        return {
          'success': true,
          'event': data,
          'message': 'Event updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': _decodeOrEmpty(response)['error'] ??
              'Failed to update event (${response.statusCode})',
        };
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

      final response = await apiClient.get(
        Uri.parse('$baseUrl/reviews/event/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'reviews': _decodeListOrEmpty(response, 'reviews'),
        };
      } else {
        final data = _decodeOrEmpty(response);
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

      final response = await apiClient.get(
        Uri.parse('$baseUrl/sentiment/organizer/events/$eventId/summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final data = _decodeOrEmpty(response);
        return {
          'success': true,
          'data': data,
        };
      } else {
        final data = _decodeOrEmpty(response);
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

      final response = await apiClient.get(
        Uri.parse('$baseUrl/sentiment/organizer/events/$eventId/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final data = _decodeOrEmpty(response);
        return {
          'success': true,
          // Exposes the sentiments array: [ { reviewId, label, score,
          // class, negativeSummary }, ... ]
          'sentiments': data['sentiments'] ?? [],
        };
      } else {
        final data = _decodeOrEmpty(response);
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

      final response = await apiClient.get(
        Uri.parse('$baseUrl/chat/rooms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        final data = _decodeOrEmpty(response);
        return {
          'success': true,
          'rooms': data['rooms'] ?? [],
        };
      } else {
        final data = _decodeOrEmpty(response);
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
