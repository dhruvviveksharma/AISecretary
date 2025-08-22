import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  // Replace with your actual Todoist API token
  // You can also use dotenv to load this from an .env file
  late String TODOIST_API_TOKEN;
  // static const String TODOIST_API_TOKEN = '6d52c22e32acedf49ce4557783645805dca0ebab';
  static const String TODOIST_BASE_URL = 'https://api.todoist.com/rest/v2';

  List<Task> tasks = [];
  List<Project> projects = [];
  bool isLoading = true;
  String? selectedProjectId;

  final TextEditingController taskController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime? selectedDueDate;

  @override
  @override
  void initState() {
    super.initState();
    TODOIST_API_TOKEN = dotenv.env['TODOIST_API_KEY'] ?? '';
    loadTasks();
    loadProjects();
  }
  // Load all tasks from Todoist
  Future<void> loadTasks() async {
    try {
      setState(() => isLoading = true);
      
      final response = await http.get(
        Uri.parse('$TODOIST_BASE_URL/tasks'),
        headers: {
          'Authorization': 'Bearer $TODOIST_API_TOKEN',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> tasksJson = json.decode(response.body);
        // sorting tasks by due date
        tasksJson.sort((a, b) {
          final dueA = a['due']?['date'] ?? '';
          final dueB = b['due']?['date'] ?? '';
          if (dueA.isEmpty && dueB.isEmpty) return 0; // both have no due date
          if (dueA.isEmpty) return 1; // a has no due date, b comes first
          if (dueB.isEmpty) return -1;
          return DateTime.parse(dueA).compareTo(DateTime.parse(dueB));
        });

        setState(() {
          tasks = tasksJson.map((json) => Task.fromJson(json)).toList();
          isLoading = false;
        });
        // print(tasksJson);


      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      showErrorDialog('Error loading tasks: $e');
    }
  }

  // Load all projects from Todoist
  Future<void> loadProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$TODOIST_BASE_URL/projects'),
        headers: {
          'Authorization': 'Bearer $TODOIST_API_TOKEN',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> projectsJson = json.decode(response.body);
        setState(() {
          projects = projectsJson.map((json) => Project.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('Error loading projects: $e');
    }
  }

  // Create a new task
  Future<void> createTask(String content, String description, String? projectId, DateTime? dueDate) async {
    try {
      final Map<String, dynamic> taskData = {
        'content': content,
        'description': description,
      };
      
      if (projectId != null && projectId.isNotEmpty) {
        taskData['project_id'] = projectId;
      }
      
      if (dueDate != null) {
        taskData['due_string'] = _formatDateForTodoist(dueDate);
      }

      final response = await http.post(
        Uri.parse('$TODOIST_BASE_URL/tasks'),
        headers: {
          'Authorization': 'Bearer $TODOIST_API_TOKEN',
          'Content-Type': 'application/json',
        },
        body: json.encode(taskData),
      );

      if (response.statusCode == 200) {
        loadTasks(); // Refresh the task list
        taskController.clear();
        descriptionController.clear();
        selectedDueDate = null;
        Navigator.pop(context);
        showSuccessDialog('Task created successfully!');
      } else {
        throw Exception('Failed to create task: ${response.statusCode}');
      }
    } catch (e) {
      showErrorDialog('Error creating task: $e');
    }
  }

  // Complete a task
  Future<void> completeTask(String taskId) async {
    try {
      final response = await http.post(
        Uri.parse('$TODOIST_BASE_URL/tasks/$taskId/close'),
        headers: {
          'Authorization': 'Bearer $TODOIST_API_TOKEN',
        },
      );

      if (response.statusCode == 204) {
        loadTasks(); // Refresh the task list
        showSuccessDialog('Task completed!');
      } else {
        throw Exception('Failed to complete task: ${response.statusCode}');
      }
    } catch (e) {
      showErrorDialog('Error completing task: $e');
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$TODOIST_BASE_URL/tasks/$taskId'),
        headers: {
          'Authorization': 'Bearer $TODOIST_API_TOKEN',
        },
      );

      if (response.statusCode == 204) {
        loadTasks(); // Refresh the task list
        showSuccessDialog('Task deleted!');
      } else {
        throw Exception('Failed to delete task: ${response.statusCode}');
      }
    } catch (e) {
      showErrorDialog('Error deleting task: $e');
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }



  // Format date for Todoist API
  String _formatDateForTodoist(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Format date for display
  String _formatDateForDisplay(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 1 && difference <= 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Show date picker
  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDueDate) {
      setState(() {
        selectedDueDate = picked;
      });
    }
  }

  void showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void showAddTaskDialog() {
    // Reset form state
    selectedDueDate = null;
    selectedProjectId = null;
    taskController.clear();
    descriptionController.clear();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Add New Task',
            style: TextStyle(color: Colors.indigo[900], fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskController,
                  decoration: InputDecoration(
                    labelText: 'Task Title *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.task),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedProjectId,
                  decoration: InputDecoration(
                    labelText: 'Project (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.folder),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('Inbox'),
                    ),
                    ...projects.map((project) => DropdownMenuItem<String>(
                      value: project.id,
                      child: Text(project.name),
                    )).toList(),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedProjectId = value;
                    });
                  },
                ),
                SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    await _selectDueDate();
                    setDialogState(() {}); // Refresh dialog to show selected date
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: selectedDueDate != null ? Colors.teal : Colors.grey,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedDueDate != null
                                ? 'Due: ${_formatDateForDisplay(selectedDueDate!)}'
                                : 'Set due date (optional)',
                            style: TextStyle(
                              color: selectedDueDate != null ? Colors.black87 : Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (selectedDueDate != null)
                          GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedDueDate = null;
                              });
                            },
                            child: Icon(
                              Icons.clear,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                selectedDueDate = null;
                selectedProjectId = null;
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (taskController.text.trim().isNotEmpty) {
                  createTask(
                    taskController.text.trim(),
                    descriptionController.text.trim(),
                    selectedProjectId,
                    selectedDueDate,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[400],
              ),
              child: Text('Add Task', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.teal[400],
        elevation: 0,
        title: Text(
          'Tasks',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: loadTasks,
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.teal),
            )
          : tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 20),
                      Text(
                        'No tasks found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Add your first task to get started!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadTasks,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: tasks.length,
                    physics: AlwaysScrollableScrollPhysics(), // Enable scrolling even with few items
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final project = projects.firstWhere(
                        (p) => p.id == task.projectId,
                        orElse: () => Project(id: '', name: 'Inbox', color: ''),
                      );

                      // Determine due date color and display
                      Color? dueDateColor;
                      String? dueDateDisplay;
                      if (task.dueDate != null) {
                        final dueDate = DateTime.tryParse(task.dueDate!);
                        if (dueDate != null) {
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
                          final difference = taskDate.difference(today).inDays;
                          
                          if (difference < 0) {
                            dueDateColor = Colors.red[700]; // Overdue
                          } else if (difference == 0) {
                            dueDateColor = Colors.orange[700]; // Today
                          } else if (difference == 1) {
                            dueDateColor = Colors.blue[700]; // Tomorrow
                          } else {
                            dueDateColor = Colors.grey[600]; // Future
                          }
                          dueDateDisplay = _formatDateForDisplay(dueDate);
                        }
                      } else if (task.dueString != null) {
                        // Fallback to human-readable string if no ISO date
                        dueDateColor = Colors.grey[600];
                        dueDateDisplay = task.dueString;
                      }

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: GestureDetector(
                            onTap: () => completeTask(task.id),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.teal,
                                  width: 2,
                                ),
                              ),
                              child: task.isCompleted
                                  ? Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.teal,
                                    )
                                  : null,
                            ),
                          ),
                          title: Text(
                            task.content,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo[900],
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (task.description.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Text(
                                  task.description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  if (project.name != 'Inbox') ...[
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        project.name,
                                        style: TextStyle(
                                          color: Colors.blue[800],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                  ],
                                  if (task.dueDate != null || task.dueString != null) ...[
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: dueDateColor?.withOpacity(0.1) ?? Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 12,
                                            color: dueDateColor,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            dueDateDisplay ?? 'Due date set',
                                            style: TextStyle(
                                              color: dueDateColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red[400],
                            ),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Delete Task'),
                                content: Text(
                                  'Are you sure you want to delete this task?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      deleteTask(task.id);
                                    },
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddTaskDialog,
        backgroundColor: Colors.teal[400],
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    taskController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}

// Task model
class Task {
  final String id;
  final String content;
  final String description;
  final bool isCompleted;
  final String? projectId;
  final String? dueDate;   // ISO 8601 date
  final String? dueString; // human-readable string

  Task({
    required this.id,
    required this.content,
    required this.description,
    required this.isCompleted,
    this.projectId,
    this.dueDate,
    this.dueString,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      content: json['content'] ?? '',
      description: json['description'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      projectId: json['project_id'],
      dueDate: json['due']?['date'],     // <-- ISO date (YYYY-MM-DD)
      dueString: json['due']?['string'], // <-- natural language
    );
  }
}

// Project model
class Project {
  final String id;
  final String name;
  final String color;

  Project({
    required this.id,
    required this.name,
    required this.color,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'] ?? '',
      color: json['color'] ?? '',
    );
  }
}