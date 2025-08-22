import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TodoistService {
  final String? _apiKey;
  final _baseUrl = "https://api.todoist.com/rest/v2";

  TodoistService() : _apiKey = dotenv.env['TODOIST_API_KEY'] {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception("Todoist API key not found in environment variables.");
    }
  }

  Map<String, String> get _headers => {
    "Authorization": "Bearer $_apiKey",
    "Content-Type": "application/json",
  };

  Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/tasks"),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Failed to fetch tasks: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching tasks: $e");
    }
  }

  Future<Map<String, dynamic>> createTask(String content, {String? dueDate, int? priority}) async {
    try {
      final body = {
        "content": content,
        if (dueDate != null) "due_string": dueDate,
        if (priority != null) "priority": priority,
      };

      final response = await http.post(
        Uri.parse("$_baseUrl/tasks"),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to create task: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error creating task: $e");
    }
  }
}


