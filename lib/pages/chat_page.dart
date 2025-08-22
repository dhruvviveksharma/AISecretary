
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:ai_secretary/services/openai_service.dart';
import 'package:ai_secretary/services/todoist_services.dart';
import 'package:ai_secretary/services/google_calendar_service.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  late OpenAIService _openAIService;
  late TodoistService _todoistService;
  // late GoogleCalendarService _calendarService;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _openAIService = OpenAIService();
    _todoistService = TodoistService();
    // _calendarService = GoogleCalendarService();
    
    // Add welcome message
    _messages.add(ChatMessage(
      message: "Hi! I'm your AI assistant. I can help you with your tasks and calendar. Try asking me things like:\n\n• What are my tasks today?\n• Show my calendar\n• Create a new task\n• What's my schedule for tomorrow?",
      isFromUser: false,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String> _buildContextFromData(String userMessage) async {
    String context = "";
    
    // Check if user is asking about tasks
    if (userMessage.toLowerCase().contains('task') || 
        userMessage.toLowerCase().contains('todo') ||
        userMessage.toLowerCase().contains('work')) {
      try {
        final tasks = await _todoistService.getTasks();
        if (tasks.isNotEmpty) {
          context += "Current tasks:\n";
          for (var task in tasks.take(10)) { // Limit to 10 tasks
            context += "- ${task['content']}";
            if (task['due'] != null) {
              context += " (due: ${task['due']['string']})";
            }
            context += "\n";
          }
        } else {
          context += "No current tasks found.\n";
        }
      } catch (e) {
        context += "Unable to fetch tasks: $e\n";
      }
    }

    // Check if user is asking about calendar/schedule
    // if (userMessage.toLowerCase().contains('calendar') || 
    //     userMessage.toLowerCase().contains('schedule') ||
    //     userMessage.toLowerCase().contains('meeting') ||
    //     userMessage.toLowerCase().contains('event')) {
    //   try {
    //     final events = await _calendarService.getEvents();
    //     if (events.isNotEmpty) {
    //       context += "\nUpcoming events:\n";
    //       for (var event in events.take(10)) { // Limit to 10 events
    //         context += "- ${event['summary'] ?? 'Untitled event'}";
    //         if (event['start'] != null) {
    //           final startTime = event['start']['dateTime'] ?? event['start']['date'];
    //           context += " (${startTime})";
    //         }
    //         context += "\n";
    //       }
    //     } else {
    //       context += "\nNo upcoming events found.\n";
    //     }
    //   } catch (e) {
    //     context += "\nUnable to fetch calendar events: $e\n";
    //   }
    // }

    if (context.isNotEmpty) {
      context = "You are a helpful AI assistant with access to the user's tasks and calendar. Here's the current data:\n\n$context\nPlease respond helpfully based on this information and the user's question.";
    }

    return context;
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(message: userMessage, isFromUser: true));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Check if user wants to create a task
      if (userMessage.toLowerCase().startsWith('create task') ||
          userMessage.toLowerCase().startsWith('add task') ||
          userMessage.toLowerCase().startsWith('new task')) {
        
        final taskContent = userMessage.replaceAll(RegExp(r'^(create|add|new)\s+task:?\s*', caseSensitive: false), '');
        
        if (taskContent.isNotEmpty) {
          try {
            await _todoistService.createTask(taskContent);
            setState(() {
              _messages.add(ChatMessage(
                message: "✅ Task created successfully: \"$taskContent\"",
                isFromUser: false,
              ));
            });
          } catch (e) {
            setState(() {
              _messages.add(ChatMessage(
                message: "❌ Failed to create task: $e",
                isFromUser: false,
              ));
            });
          }
        } else {
          setState(() {
            _messages.add(ChatMessage(
              message: "Please specify the task content. Example: 'Create task: Buy groceries'",
              isFromUser: false,
            ));
          });
        }
      } else if (userMessage.toLowerCase().startsWith('create event') ||
                 userMessage.toLowerCase().startsWith('add event') ||
                 userMessage.toLowerCase().startsWith('schedule')) {
        
        // Handle event creation through AI parsing
        final context = "You are helping to create a calendar event. Parse the user's request and extract event details. If information is missing, ask for clarification.";
        final response = await _openAIService.sendMessage(
          "Parse this event creation request and tell me what information you have and what's missing: $userMessage", 
          context: context
        );
        
        setState(() {
          _messages.add(ChatMessage(message: response, isFromUser: false));
        });
      } else {
        // Regular AI conversation with context
        final context = await _buildContextFromData(userMessage);
        final response = await _openAIService.sendMessage(userMessage, context: context);
        
        setState(() {
          _messages.add(ChatMessage(message: response, isFromUser: false));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          message: "Sorry, I encountered an error: $e",
          isFromUser: false,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Assistant'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          if (_isLoading)
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(width: 60),
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(width: 12),
                  Text('AI is thinking...', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask about your tasks or schedule...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading,
                  ),
                ),
                SizedBox(width: 12),
                FloatingActionButton(
                  mini: true,
                  onPressed: _isLoading ? null : _sendMessage,
                  child: Icon(Icons.send),
                  backgroundColor: _isLoading ? Colors.grey : Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String message;
  final bool isFromUser;
  final DateTime timestamp;

  ChatMessage({
    required this.message,
    required this.isFromUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isFromUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isFromUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isFromUser 
                    ? Colors.blue 
                    : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: message.isFromUser 
                      ? Radius.circular(16) 
                      : Radius.circular(4),
                  bottomRight: message.isFromUser 
                      ? Radius.circular(4) 
                      : Radius.circular(16),
                ),
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  color: message.isFromUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (message.isFromUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[600], size: 18),
            ),
          ],
        ],
      ),
    );
  }
}