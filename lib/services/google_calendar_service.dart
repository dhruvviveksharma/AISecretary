// import 'dart:convert';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:googleapis_auth/auth_io.dart';
// import 'package:googleapis/calendar/v3.dart';
// import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class GoogleCalendarService {
//   CalendarApi? _calendarApi;
//   http.Client? _httpClient;
  
//   final _scopes = const [
//     'https://www.googleapis.com/auth/calendar.events',
//     'https://www.googleapis.com/auth/calendar.readonly',
//   ];

//   bool get isAuthenticated => _calendarApi != null && _httpClient != null;

//   Future<http.Client> getAuthenticatedClient() async {
//     final clientId = dotenv.env['GOOGLE_CALENDAR_CLIENT_ID'];
//     final clientSecret = dotenv.env['GOOGLE_CALENDAR_CLIENT_SECRET'];

//     if (clientId == null || clientSecret == null) {
//       throw Exception('Google Calendar client ID or secret not found in .env file.');
//     }

//     final clientCredentials = ClientId(clientId, clientSecret);
    
//     try {
//       // Try to get cached credentials first
//       final cachedClient = await _getCachedClient(clientCredentials);
//       if (cachedClient != null) {
//         _httpClient = cachedClient;
//         _calendarApi = CalendarApi(cachedClient);
//         return cachedClient;
//       }

//       // Launch browser for user consent
//       var client = await clientViaUserConsent(clientCredentials, _scopes, (url) {
//         launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
//       });

//       // Cache the credentials
//       await _cacheCredentials(client);
      
//       _httpClient = client;
//       _calendarApi = CalendarApi(client);
      
//       return client;
//     } catch (e) {
//       throw Exception('Authentication failed: $e');
//     }
//   }

//   Future<http.Client?> _getCachedClient(ClientId clientCredentials) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final cachedToken = prefs.getString('google_calendar_token');
//       final cachedRefreshToken = prefs.getString('google_calendar_refresh_token');
//       final expiryString = prefs.getString('google_calendar_token_expiry');
      
//       if (cachedToken == null || cachedRefreshToken == null || expiryString == null) {
//         return null;
//       }

//       final expiry = DateTime.parse(expiryString);
//       final credentials = AccessCredentials(
//         AccessToken('Bearer', cachedToken, expiry),
//         cachedRefreshToken,
//         _scopes,
//       );

//       // Check if token is expired and refresh if needed
//       if (DateTime.now().isAfter(expiry.subtract(Duration(minutes: 5)))) {
//         return await refreshCredentials(clientCredentials, credentials);
//       }

//       return authenticatedClient(http.Client(), credentials);
//     } catch (e) {
//       print('Failed to get cached client: $e');
//       return null;
//     }
//   }

//   Future<void> _cacheCredentials(http.Client client) async {
//     try {
//       // This is a simplified version - in a real implementation, you'd need to
//       // properly extract and store the credentials from the authenticated client
//       final prefs = await SharedPreferences.getInstance();
//       // Store token data when available
//       // This would need to be implemented based on your specific OAuth flow
//     } catch (e) {
//       print('Failed to cache credentials: $e');
//     }
//   }

//   Future<http.Client> refreshCredentials(ClientId clientId, AccessCredentials credentials) async {
//     try {
//       final newCredentials = await refreshCredentials(clientId, credentials);
//       final client = authenticatedClient(http.Client(), newCredentials as AccessCredentials);
//       await _cacheCredentials(client);
//       return client;
//     } catch (e) {
//       throw Exception('Failed to refresh credentials: $e');
//     }
//   }

//   // Get events from calendar
//   Future<List<Map<String, dynamic>>> getEvents({
//     DateTime? timeMin,
//     DateTime? timeMax,
//     int maxResults = 50,
//     String? calendarId = 'primary',
//   }) async {
//     if (_calendarApi == null) {
//       throw Exception('Calendar API not authenticated. Please authenticate first.');
//     }

//     try {
//       timeMin ??= DateTime.now();
//       timeMax ??= DateTime.now().add(Duration(days: 30));

//       final events = await _calendarApi!.events.list(
//         calendarId!,
//         timeMin: timeMin,
//         timeMax: timeMax,
//         maxResults: maxResults,
//         singleEvents: true,
//         orderBy: 'startTime',
//       );

//       return events.items?.map((event) => {
//         'id': event.id,
//         'summary': event.summary ?? 'No Title',
//         'description': event.description ?? '',
//         'start': _formatDateTime(event.start),
//         'end': _formatDateTime(event.end),
//         'location': event.location ?? '',
//         'attendees': event.attendees?.map((a) => a.email).toList() ?? [],
//         'status': event.status ?? '',
//         'htmlLink': event.htmlLink ?? '',
//       }).toList() ?? [];
//     } catch (e) {
//       throw Exception('Failed to fetch events: $e');
//     }
//   }

//   // Get today's events
//   Future<List<Map<String, dynamic>>> getTodayEvents() async {
//     final now = DateTime.now();
//     final startOfDay = DateTime(now.year, now.month, now.day);
//     final endOfDay = startOfDay.add(Duration(days: 1));

//     return await getEvents(
//       timeMin: startOfDay,
//       timeMax: endOfDay,
//     );
//   }

//   // Get events for a specific date
//   Future<List<Map<String, dynamic>>> getEventsForDate(DateTime date) async {
//     final startOfDay = DateTime(date.year, date.month, date.day);
//     final endOfDay = startOfDay.add(Duration(days: 1));

//     return await getEvents(
//       timeMin: startOfDay,
//       timeMax: endOfDay,
//     );
//   }

//   // Create a new event
//   Future<Map<String, dynamic>> createEvent({
//     required String summary,
//     String? description,
//     required DateTime startTime,
//     required DateTime endTime,
//     String? location,
//     List<String>? attendeeEmails,
//     String? calendarId = 'primary',
//   }) async {
//     if (_calendarApi == null) {
//       throw Exception('Calendar API not authenticated. Please authenticate first.');
//     }

//     try {
//       final event = Event()
//         ..summary = summary
//         ..description = description
//         ..location = location
//         ..start = EventDateTime()
//         ..end = EventDateTime();

//       // Set start time
//       if (_isAllDayEvent(startTime, endTime)) {
//         event.start!.date = DateTime(startTime.year, startTime.month, startTime.day);
//         event.end!.date = DateTime(endTime.year, endTime.month, endTime.day);
//       } else {
//         event.start!.dateTime = startTime;
//         event.end!.dateTime = endTime;
//       }

//       // Add attendees if provided
//       if (attendeeEmails != null && attendeeEmails.isNotEmpty) {
//         event.attendees = attendeeEmails.map((email) => EventAttendee()..email = email).toList();
//       }

//       final createdEvent = await _calendarApi!.events.insert(event, calendarId!);

//       return {
//         'id': createdEvent.id,
//         'summary': createdEvent.summary ?? summary,
//         'description': createdEvent.description ?? description ?? '',
//         'start': _formatDateTime(createdEvent.start),
//         'end': _formatDateTime(createdEvent.end),
//         'location': createdEvent.location ?? location ?? '',
//         'htmlLink': createdEvent.htmlLink ?? '',
//         'status': createdEvent.status ?? '',
//       };
//     } catch (e) {
//       throw Exception('Failed to create event: $e');
//     }
//   }

//   // Update an existing event
//   Future<Map<String, dynamic>> updateEvent({
//     required String eventId,
//     String? summary,
//     String? description,
//     DateTime? startTime,
//     DateTime? endTime,
//     String? location,
//     String? calendarId = 'primary',
//   }) async {
//     if (_calendarApi == null) {
//       throw Exception('Calendar API not authenticated. Please authenticate first.');
//     }

//     try {
//       // First get the existing event
//       final existingEvent = await _calendarApi!.events.get(calendarId!, eventId);

//       // Update fields if provided
//       if (summary != null) existingEvent.summary = summary;
//       if (description != null) existingEvent.description = description;
//       if (location != null) existingEvent.location = location;
      
//       if (startTime != null && endTime != null) {
//         if (_isAllDayEvent(startTime, endTime)) {
//           existingEvent.start!.date = DateTime(startTime.year, startTime.month, startTime.day);
//           existingEvent.end!.date = DateTime(endTime.year, endTime.month, endTime.day);
//           existingEvent.start!.dateTime = null;
//           existingEvent.end!.dateTime = null;
//         } else {
//           existingEvent.start!.dateTime = startTime;
//           existingEvent.end!.dateTime = endTime;
//           existingEvent.start!.date = null;
//           existingEvent.end!.date = null;
//         }
//       }

//       final updatedEvent = await _calendarApi!.events.update(existingEvent, calendarId, eventId);

//       return {
//         'id': updatedEvent.id,
//         'summary': updatedEvent.summary ?? '',
//         'description': updatedEvent.description ?? '',
//         'start': _formatDateTime(updatedEvent.start),
//         'end': _formatDateTime(updatedEvent.end),
//         'location': updatedEvent.location ?? '',
//         'htmlLink': updatedEvent.htmlLink ?? '',
//         'status': updatedEvent.status ?? '',
//       };
//     } catch (e) {
//       throw Exception('Failed to update event: $e');
//     }
//   }

//   // Delete an event
//   Future<void> deleteEvent(String eventId, {String calendarId = 'primary'}) async {
//     if (_calendarApi == null) {
//       throw Exception('Calendar API not authenticated. Please authenticate first.');
//     }

//     try {
//       await _calendarApi!.events.delete(calendarId, eventId);
//     } catch (e) {
//       throw Exception('Failed to delete event: $e');
//     }
//   }

//   // Get upcoming events (next 7 days)
//   Future<List<Map<String, dynamic>>> getUpcomingEvents({int days = 7}) async {
//     final now = DateTime.now();
//     final future = now.add(Duration(days: days));

//     return await getEvents(
//       timeMin: now,
//       timeMax: future,
//     );
//   }

//   // Search events by query
//   Future<List<Map<String, dynamic>>> searchEvents(String query, {int maxResults = 20}) async {
//     if (_calendarApi == null) {
//       throw Exception('Calendar API not authenticated. Please authenticate first.');
//     }

//     try {
//       final events = await _calendarApi!.events.list(
//         'primary',
//         q: query,
//         maxResults: maxResults,
//         singleEvents: true,
//         orderBy: 'startTime',
//       );

//       return events.items?.map((event) => {
//         'id': event.id,
//         'summary': event.summary ?? 'No Title',
//         'description': event.description ?? '',
//         'start': _formatDateTime(event.start),
//         'end': _formatDateTime(event.end),
//         'location': event.location ?? '',
//         'htmlLink': event.htmlLink ?? '',
//       }).toList() ?? [];
//     } catch (e) {
//       throw Exception('Failed to search events: $e');
//     }
//   }

//   // Helper method to format DateTime from EventDateTime
//   Map<String, dynamic> _formatDateTime(EventDateTime? eventDateTime) {
//     if (eventDateTime == null) {
//       return {'dateTime': null, 'date': null, 'formatted': 'No time specified'};
//     }

//     if (eventDateTime.dateTime != null) {
//       return {
//         'dateTime': eventDateTime.dateTime!.toIso8601String(),
//         'date': null,
//         'formatted': _formatDateTimeString(eventDateTime.dateTime!),
//       };
//     } else if (eventDateTime.date != null) {
//       return {
//         'dateTime': null,
//         'date': eventDateTime.date!.toIso8601String(),
//         'formatted': _formatDateString(eventDateTime.date!),
//       };
//     }

//     return {'dateTime': null, 'date': null, 'formatted': 'No time specified'};
//   }

//   String _formatDateTimeString(DateTime dateTime) {
//     return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
//   }

//   String _formatDateString(DateTime date) {
//     return '${date.day}/${date.month}/${date.year} (All day)';
//   }

//   bool _isAllDayEvent(DateTime start, DateTime end) {
//     return start.hour == 0 && start.minute == 0 && start.second == 0 &&
//            end.hour == 0 && end.minute == 0 && end.second == 0;
//   }

//   // Parse natural language date/time
//   DateTime? parseDateTime(String input) {
//     final now = DateTime.now();
//     final lowerInput = input.toLowerCase().trim();

//     // Handle "today" and "tomorrow"
//     if (lowerInput.contains('today')) {
//       return DateTime(now.year, now.month, now.day);
//     } else if (lowerInput.contains('tomorrow')) {
//       final tomorrow = now.add(Duration(days: 1));
//       return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
//     }

//     // Handle "next monday", "next tuesday", etc.
//     final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
//     for (int i = 0; i < weekdays.length; i++) {
//       if (lowerInput.contains('next ${weekdays[i]}')) {
//         final daysUntil = (i + 1 - now.weekday + 7) % 7;
//         final targetDay = daysUntil == 0 ? 7 : daysUntil; // If today is the target day, go to next week
//         return now.add(Duration(days: targetDay));
//       }
//     }

//     // Handle time parsing (simplified)
//     final timeRegex = RegExp(r'(\d{1,2}):?(\d{2})?\s*(am|pm)?', caseSensitive: false);
//     final timeMatch = timeRegex.firstMatch(input);
    
//     if (timeMatch != null) {
//       int hour = int.parse(timeMatch.group(1)!);
//       int minute = timeMatch.group(2) != null ? int.parse(timeMatch.group(2)!) : 0;
//       final ampm = timeMatch.group(3)?.toLowerCase();
      
//       if (ampm == 'pm' && hour != 12) hour += 12;
//       if (ampm == 'am' && hour == 12) hour = 0;
      
//       return DateTime(now.year, now.month, now.day, hour, minute);
//     }

//     // Return null if no recognizable pattern found
//     return null;
//   }

//   void dispose() {
//     _httpClient?.close();
//   }
// }