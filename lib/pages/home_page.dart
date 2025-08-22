import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import your page files here
import 'chat_page.dart';
import 'tasks_page.dart';
import 'calendar_page.dart';
import 'notes_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;

  // Sign out function
  void signUserOut() async {
    await FirebaseAuth.instance.signOut();
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (context) => LoginPage(onTap: )),
    // );
  }

  // Service navigation functions
  void navigateToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatPage()),
    );
    print("Navigate to Chat");
  }

  void navigateToTasks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TasksPage()),
    );
    print("Navigate to Tasks");
  }

  void navigateToCalendar() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => CalendarPage()),
    // );
    print("Navigate to Calendar");
  }

  void navigateToNotes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotesPage()),
    );
    print("Navigate to Notes");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.teal[400],
        elevation: 0,
        title: Text(
          'AI Secretary',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: signUserOut,
            icon: Icon(
              Icons.logout,
              color: Colors.white,
            ),
          ),
          
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[900],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      user.email ?? 'User',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'How can I assist you today?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.indigo[700],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // Services Section
              Text(
                'Services',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[900],
                ),
              ),

              SizedBox(height: 20),

              // Services Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    // Chat Service
                    ServiceCard(
                      icon: Icons.chat_bubble_outline,
                      title: 'Chat',
                      subtitle: 'Talk with AI',
                      color: Colors.blue,
                      onTap: navigateToChat,
                    ),

                    // Tasks Service
                    ServiceCard(
                      icon: Icons.add_task_outlined,
                      title: 'Tasks',
                      subtitle: 'View Tasks',
                      color: Colors.green,
                      onTap: navigateToTasks,
                    ),

                    // Calendar Service
                    ServiceCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Calendar',
                      subtitle: 'Manage schedule',
                      color: Colors.orange,
                      onTap: navigateToCalendar,
                    ),

                    // Notes Service
                    ServiceCard(
                      icon: Icons.note_outlined,
                      title: 'Notes',
                      subtitle: 'Quick notes',
                      color: Colors.purple,
                      onTap: navigateToNotes,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Quick Actions Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.teal[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.teal[600],
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: Start a chat to get instant AI assistance!',
                        style: TextStyle(
                          color: Colors.teal[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with colored background
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),

              SizedBox(height: 15),

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[900],
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 5),

              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}