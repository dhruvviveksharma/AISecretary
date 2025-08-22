// import 'dart:io';
// import 'package:ai_secretary/pages/home_page.dart';
// import 'package:flutter/material.dart';
// import 'package:googleapis/calendar/v3.dart' hide Colors;
// import 'package:googleapis_auth/auth_io.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:intl/intl.dart';
// import 'package:googleapis_auth/googleapis_auth.dart' as auth;
// import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// class GoogleAuthService {
//   static const List<String> _scopes = [
//     'https://www.googleapis.com/auth/calendar',
//     'https://www.googleapis.com/auth/calendar.events',
//   ];

//   static final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: _scopes,
//   );

//   static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
//   static bool get isSignedIn => _googleSignIn.currentUser != null;

//   static Future<GoogleSignInAccount?> signIn() async {
//     try {
//       final GoogleSignInAccount? account = await _googleSignIn.signIn();
//       return account;
//     } catch (error) {
//       print('Error signing in: $error');
//       return null;
//     }
//   }

//   static Future<void> signOut() async {
//     await _googleSignIn.signOut();
//   }

//   static Future<auth.AuthClient?> getAuthClient() async {
//     final GoogleSignInAccount? account = _googleSignIn.currentUser;
//     if (account == null) return null;
    
//     return await account.authClient;
//   }

//   static Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
//       _googleSignIn.onCurrentUserChanged;
// }

// enum CalendarView { schedule, day, week, month }

// class CalendarPage extends StatefulWidget {
//   const CalendarPage({super.key});

//   @override
//   State<CalendarPage> createState() => _CalendarPageState();
// }

// class _CalendarPageState extends State<CalendarPage> with TickerProviderStateMixin {
//   List<CalendarEvent> events = [];
//   bool isLoading = true;
//   CalendarView currentView = CalendarView.month;
//   DateTime selectedDate = DateTime.now();
//   DateTime currentMonth = DateTime.now();
//   late PageController monthPageController;
//   late PageController weekPageController;
//   late PageController dayPageController;
//   late AnimationController fabAnimationController;
//   late Animation<double> fabAnimation;
//   bool showFabMenu = false;
  
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   @override
//   void initState() {
//     super.initState();
//     monthPageController = PageController(initialPage: 500);
//     weekPageController = PageController(initialPage: 500);
//     dayPageController = PageController(initialPage: 500);
//     fabAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: fabAnimationController, curve: Curves.elasticOut),
//     );
//     fetchEvents();
//   }

//   @override
//   void dispose() {
//     monthPageController.dispose();
//     weekPageController.dispose();
//     dayPageController.dispose();
//     fabAnimationController.dispose();
//     super.dispose();
//   }

//   Future<void> fetchEvents() async {
//     setState(() => isLoading = true);
    
//     try {
//       final apiKey = dotenv.env['GOOGLE_CALENDAR_API_KEY'];
//       if (apiKey == null) {
//         throw Exception('Google Calendar API key not found in .env file');
//       }
      
//       final calendarId = 'dhruvviveksharma@gmail.com';
//       final now = DateTime.now();
//       final timeMin = DateTime(now.year - 1, 1, 1).toUtc().toIso8601String();
//       final timeMax = DateTime(now.year + 1, 12, 31).toUtc().toIso8601String();
      
//       final url = 'https://www.googleapis.com/calendar/v3/calendars/$calendarId/events'
//           '?key=$apiKey'
//           '&orderBy=startTime'
//           '&timeMin=$timeMin'
//           '&timeMax=$timeMax'
//           '&singleEvents=true'
//           '&maxResults=1000';
          
//       final response = await http.get(Uri.parse(url));
      
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final eventItems = data['items'] as List? ?? [];
        
//         setState(() {
//           events = eventItems
//               .map((item) => CalendarEvent.fromJson(item))
//               .where((event) => event.title.isNotEmpty)
//               .toList();
//           isLoading = false;
//         });
//       } else {
//         throw Exception('Failed to load events: ${response.statusCode}');
//       }
//     } catch (e) {
//       setState(() => isLoading = false);
//       _showErrorSnackBar('Error: $e');
//     }
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red[600],
//         action: SnackBarAction(
//           label: 'RETRY',
//           textColor: Colors.white,
//           onPressed: fetchEvents,
//         ),
//       ),
//     );
//   }

//   List<CalendarEvent> getEventsForDate(DateTime date) {
//     return events.where((event) {
//       if (event.startTime == null) return false;
//       final eventDate = event.startTime!;
      
//       if (event.isAllDay) {
//         return eventDate.year == date.year &&
//             eventDate.month == date.month &&
//             eventDate.day == date.day;
//       }
      
//       final localEventDate = eventDate.toLocal();
//       return localEventDate.year == date.year &&
//           localEventDate.month == date.month &&
//           localEventDate.day == date.day;
//     }).toList()..sort((a, b) {
//       if (a.startTime == null || b.startTime == null) return 0;
//       return a.startTime!.compareTo(b.startTime!);
//     });
//   }

//   Widget _buildAppBar() {
//     String title = '';
//     switch (currentView) {
//       case CalendarView.schedule:
//         title = 'Schedule';
//         break;
//       case CalendarView.day:
//         title = DateFormat('EEEE, MMM d').format(selectedDate);
//         break;
//       case CalendarView.week:
//         final weekStart = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
//         final weekEnd = weekStart.add(const Duration(days: 6));
//         title = '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}';
//         break;
//       case CalendarView.month:
//         title = DateFormat('MMMM y').format(currentMonth);
//         break;
//     }

//     return AppBar(
//       backgroundColor: Colors.orange[400],
//       elevation: 0,
//       leading: IconButton(
//         icon: const Icon(Icons.menu, color: Colors.black87),
//         onPressed: () => _scaffoldKey.currentState?.openDrawer(),
//       ),
//       title: Row(
//         children: [

//           if (currentView != CalendarView.schedule)
//             IconButton(
//               icon: Icon(Icons.today, color: Colors.blue[900], size: 20),
//               onPressed: () {
//                 setState(() {
//                   selectedDate = DateTime.now();
//                   currentMonth = DateTime.now();
//                 });
//                 _jumpToToday();
//               },
//             ),
//           Expanded(
//             child: Text(
//               title,
//               style: const TextStyle(
//                 color: Colors.black87,
//                 fontSize: 20,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//       actions: [
//         IconButton(
//           icon: Icon(Icons.home, color: Colors.blue[900]),
//           onPressed: () {
//             // Implement search
//             Navigator.pop(context);
//           },
//         ),
//         IconButton(
//           icon: const Icon(Icons.search, color: Colors.black54),
//           onPressed: () {
//             // Implement search
//             _showSearchDialog();
//           },
//         ),
//         PopupMenuButton<String>(
//           icon: const Icon(Icons.more_vert, color: Colors.black54),
//           onSelected: (value) {
//             switch (value) {
//               case 'refresh':
//                 fetchEvents();
//                 break;
//               case 'settings':
//                 _showSettingsDialog();
//                 break;
//             }
//           },
//           itemBuilder: (context) => [
//             const PopupMenuItem(
//               value: 'refresh',
//               child: Row(
//                 children: [
//                   Icon(Icons.refresh, size: 20),
//                   SizedBox(width: 12),
//                   Text('Refresh'),
//                 ],
//               ),
//             ),
//             const PopupMenuItem(
//               value: 'settings',
//               child: Row(
//                 children: [
//                   Icon(Icons.settings, size: 20),
//                   SizedBox(width: 12),
//                   Text('Settings'),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ],
//       bottom: PreferredSize(
//         preferredSize: const Size.fromHeight(60),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Row(
//             children: [
//               _buildViewButton('S', CalendarView.schedule),
//               _buildViewButton('D', CalendarView.day),
//               _buildViewButton('W', CalendarView.week),
//               _buildViewButton('M', CalendarView.month),
//               const Spacer(),
//               if (currentView != CalendarView.schedule) ...[
//                 IconButton(
//                   icon: const Icon(Icons.chevron_left, color: Colors.black54),
//                   onPressed: _navigatePrevious,
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.chevron_right, color: Colors.black54),
//                   onPressed: _navigateNext,
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildViewButton(String label, CalendarView view) {
//     final isSelected = currentView == view;
//     return Container(
//       margin: const EdgeInsets.only(right: 8),
//       child: GestureDetector(
//         onTap: () => setState(() => currentView = view),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           decoration: BoxDecoration(
//             color: isSelected ? Colors.blue[900] : Colors.transparent,
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Text(
//             label,
//             style: TextStyle(
//               color: isSelected ? Colors.white : Colors.black54,
//               fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//               fontSize: 14,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _navigatePrevious() {
//     switch (currentView) {
//       case CalendarView.day:
//         dayPageController.previousPage(
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//         break;
//       case CalendarView.week:
//         weekPageController.previousPage(
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//         break;
//       case CalendarView.month:
//         monthPageController.previousPage(
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//         break;
//       case CalendarView.schedule:
//         break;
//     }
//   }

//   void _navigateNext() {
//     switch (currentView) {
//       case CalendarView.day:
//         dayPageController.nextPage(
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//         break;
//       case CalendarView.week:
//         weekPageController.nextPage(
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//         break;
//       case CalendarView.month:
//         monthPageController.nextPage(
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//         break;
//       case CalendarView.schedule:
//         break;
//     }
//   }

//   void _jumpToToday() {
//     setState(() {
//       selectedDate = DateTime.now();
//       currentMonth = DateTime.now();
//     });
    
//     switch (currentView) {
//       case CalendarView.day:
//         dayPageController.animateToPage(
//           500,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//         break;
//       case CalendarView.week:
//         weekPageController.animateToPage(
//           500,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//         break;
//       case CalendarView.month:
//         monthPageController.animateToPage(
//           500,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeInOut,
//         );
//         break;
//       case CalendarView.schedule:
//         break;
//     }
//   }

//   Widget _buildScheduleView() {
//     final now = DateTime.now();
//     final upcomingEvents = events
//         .where((event) => event.startTime != null && 
//                event.startTime!.isAfter(now.subtract(const Duration(days: 1))))
//         .take(50)
//         .toList();

//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: upcomingEvents.length,
//       itemBuilder: (context, index) {
//         final event = upcomingEvents[index];
//         final eventDate = event.startTime!;
//         final isToday = _isSameDay(eventDate, now);
//         final isTomorrow = _isSameDay(eventDate, now.add(const Duration(days: 1)));
        
//         String dateLabel = '';
//         if (isToday) {
//           dateLabel = 'Today';
//         } else if (isTomorrow) {
//           dateLabel = 'Tomorrow';
//         } else {
//           dateLabel = DateFormat('MMM d').format(eventDate);
//         }

//         final showDateHeader = index == 0 || 
//                               !_isSameDay(eventDate, upcomingEvents[index - 1].startTime!);

//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (showDateHeader) ...[
//               if (index > 0) const SizedBox(height: 24),
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: Text(
//                   dateLabel,
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ),
//             ],
//             _buildScheduleEventCard(event),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildScheduleEventCard(CalendarEvent event) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: Colors.grey[200]!),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: ListTile(
//         leading: Container(
//           width: 4,
//           height: 40,
//           decoration: BoxDecoration(
//             color: Colors.blue[900],
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//         title: Text(
//           event.title,
//           style: const TextStyle(
//             fontWeight: FontWeight.w500,
//             fontSize: 16,
//           ),
//         ),
//         subtitle: Text(
//           event.isAllDay
//               ? 'All day'
//               : DateFormat('h:mm a').format(event.startTime!.toLocal()),
//           style: TextStyle(
//             color: Colors.grey[600],
//             fontSize: 14,
//           ),
//         ),
//         trailing: PopupMenuButton<String>(
//           icon: const Icon(Icons.more_vert, size: 20),
//           onSelected: (value) => _handleEventAction(value, event),
//           itemBuilder: (context) => [
//             const PopupMenuItem(value: 'edit', child: Text('Edit')),
//             const PopupMenuItem(value: 'delete', child: Text('Delete')),
//           ],
//         ),
//         onTap: () => _showEventDetails(event),
//       ),
//     );
//   }

//   Widget _buildDayView() {
//     return PageView.builder(
//       controller: dayPageController,
//       onPageChanged: (index) {
//         setState(() {
//           selectedDate = DateTime.now().add(Duration(days: index - 500));
//         });
//       },
//       itemBuilder: (context, index) {
//         final date = DateTime.now().add(Duration(days: index - 500));
//         final dayEvents = getEventsForDate(date);
        
//         return _buildDayContent(date, dayEvents);
//       },
//     );
//   }

//   Widget _buildDayContent(DateTime date, List<CalendarEvent> dayEvents) {
//     final allDayEvents = dayEvents.where((e) => e.isAllDay).toList();
//     final timedEvents = dayEvents.where((e) => !e.isAllDay).toList();

//     return Column(
//       children: [
//         if (allDayEvents.isNotEmpty) ...[
//           Container(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: allDayEvents.map((event) => Container(
//                 margin: const EdgeInsets.only(bottom: 4),
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.blue[900],
//                   borderRadius: BorderRadius.circular(4),
//                   border: Border.all(color: Colors.blue[900]!),
//                 ),
//                 child: Text(
//                   event.title,
//                   style: TextStyle(
//                     color: Colors.blue[900],
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               )).toList(),
//             ),
//           ),
//           const Divider(height: 1),
//         ],
//         Expanded(
//           child: _buildHourlyGrid(date, timedEvents),
//         ),
//       ],
//     );
//   }

//   Widget _buildHourlyGrid(DateTime date, List<CalendarEvent> timedEvents) {
//     return SingleChildScrollView(
//       child: SizedBox(
//         height: 24 * 60,
//         child: Stack(
//           children: [
//             // Hour lines and labels
//             Column(
//               children: List.generate(24, (hour) {
//                 return Container(
//                   height: 60,
//                   decoration: BoxDecoration(
//                     border: Border(
//                       top: BorderSide(
//                         color: Colors.grey[200]!,
//                         width: hour == 0 ? 0 : 0.5,
//                       ),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       SizedBox(
//                         width: 60,
//                         child: Text(
//                           hour == 0 ? '12 AM' : 
//                           hour < 12 ? '$hour AM' :
//                           hour == 12 ? '12 PM' : '${hour - 12} PM',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                       Expanded(
//                         child: Container(
//                           height: 60,
//                           decoration: BoxDecoration(
//                             border: Border(
//                               left: BorderSide(color: Colors.grey[200]!),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }),
//             ),
//             // Current time indicator
//             if (_isSameDay(date, DateTime.now())) _buildCurrentTimeIndicator(),
//             // Events
//             ...timedEvents.map((event) => _buildTimedEventWidget(event)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCurrentTimeIndicator() {
//     final now = DateTime.now();
//     final topPosition = (now.hour * 60.0) + now.minute;
    
//     return Positioned(
//       top: topPosition,
//       left: 0,
//       right: 0,
//       child: Row(
//         children: [
//           Container(
//             width: 60,
//             alignment: Alignment.center,
//             child: Container(
//               width: 8,
//               height: 8,
//               decoration: const BoxDecoration(
//                 color: Colors.red,
//                 shape: BoxShape.circle,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Container(
//               height: 2,
//               color: Colors.red,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTimedEventWidget(CalendarEvent event) {
//     final startTime = event.startTime!.toLocal();
//     final topPosition = (startTime.hour * 60.0) + startTime.minute;
    
//     Duration duration = const Duration(hours: 1);
//     if (event.endTime != null) {
//       final endTime = event.endTime!.toLocal();
//       if (_isSameDay(startTime, endTime)) {
//         duration = endTime.difference(startTime);
//       }
//     }
    
//     final height = duration.inMinutes.toDouble().clamp(30.0, double.infinity);
    
//     return Positioned(
//       top: topPosition,
//       left: 65,
//       right: 8,
//       child: GestureDetector(
//         onTap: () => _showEventDetails(event),
//         child: Container(
//           height: height,
//           decoration: BoxDecoration(
//             color: Colors.orange[200], // event card details
//             borderRadius: BorderRadius.circular(4),
//             border: Border.all(color: Colors.orange[700]!),
//           ),
//           padding: const EdgeInsets.all(4),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 event.title,
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.blue[900],
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               if (height > 40)
//                 Text(
//                   DateFormat('h:mm a').format(startTime),
//                   style: TextStyle(
//                     fontSize: 10,
//                     color: Colors.blue[900],
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildWeekView() {
//     return PageView.builder(
//       controller: weekPageController,
//       onPageChanged: (index) {
//         final weekStart = DateTime.now()
//             .add(Duration(days: (index - 500) * 7))
//             .subtract(Duration(days: DateTime.now().weekday - 1));
//         setState(() {
//           selectedDate = weekStart;
//         });
//       },
//       itemBuilder: (context, index) {
//         final weekStart = DateTime.now()
//             .add(Duration(days: (index - 500) * 7))
//             .subtract(Duration(days: DateTime.now().weekday - 1));
            
//         return _buildWeekContent(weekStart);
//       },
//     );
//   }

//   Widget _buildWeekContent(DateTime weekStart) {
//     return Column(
//       children: [
//         // Week header
//         Container(
//           padding: const EdgeInsets.symmetric(vertical: 8),
//           decoration: BoxDecoration(
//             border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
//           ),
//           child: Row(
//             children: [
//               const SizedBox(width: 60),
//               ...List.generate(7, (index) {
//                 final day = weekStart.add(Duration(days: index));
//                 final isToday = _isSameDay(day, DateTime.now());
//                 final isSelected = _isSameDay(day, selectedDate);
                
//                 return Expanded(
//                   child: GestureDetector(
//                     onTap: () => setState(() => selectedDate = day),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(vertical: 8),
//                       decoration: BoxDecoration(
//                         color: isSelected ? Colors.blue[50] : null,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Column(
//                         children: [
//                           Text(
//                             DateFormat('EEE').format(day),
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey[600],
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Container(
//                             width: 32,
//                             height: 32,
//                             decoration: BoxDecoration(
//                               color: isToday ? Colors.blue : null,
//                               shape: BoxShape.circle,
//                             ),
//                             alignment: Alignment.center,
//                             child: Text(
//                               '${day.day}',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w500,
//                                 color: isToday ? Colors.white : Colors.black87,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               }),
//             ],
//           ),
//         ),
//         Expanded(
//           child: _buildWeekGrid(weekStart),
//         ),
//       ],
//     );
//   }

//   Widget _buildWeekGrid(DateTime weekStart) {
//     return SingleChildScrollView(
//       child: SizedBox(
//         height: 24 * 60,
//         child: Row(
//           children: [
//             // Hour labels
//             SizedBox(
//               width: 60,
//               child: Column(
//                 children: List.generate(24, (hour) {
//                   return Container(
//                     height: 60,
//                     alignment: Alignment.topCenter,
//                     padding: const EdgeInsets.only(top: 4),
//                     child: Text(
//                       hour == 0 ? '12 AM' : 
//                       hour < 12 ? '$hour AM' :
//                       hour == 12 ? '12 PM' : '${hour - 12} PM',
//                       style: TextStyle(
//                         fontSize: 10,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   );
//                 }),
//               ),
//             ),
//             // Week columns
//             ...List.generate(7, (dayIndex) {
//               final day = weekStart.add(Duration(days: dayIndex));
//               final dayEvents = getEventsForDate(day).where((e) => !e.isAllDay).toList();
              
//               return Expanded(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     border: Border(
//                       left: BorderSide(color: Colors.grey[200]!),
//                     ),
//                   ),
//                   child: Stack(
//                     children: [
//                       // Grid lines
//                       Column(
//                         children: List.generate(24, (hour) {
//                           return Container(
//                             height: 60,
//                             decoration: BoxDecoration(
//                               border: Border(
//                                 top: BorderSide(color: Colors.grey[100]!, width: 0.5),
//                               ),
//                             ),
//                           );
//                         }),
//                       ),
//                       // Current time line
//                       if (_isSameDay(day, DateTime.now())) 
//                         _buildCurrentTimeIndicatorWeek(),
//                       // Events
//                       ...dayEvents.map((event) => _buildWeekEventWidget(event)),
//                     ],
//                   ),
//                 ),
//               );
//             }),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCurrentTimeIndicatorWeek() {
//     final now = DateTime.now();
//     final topPosition = (now.hour * 60.0) + now.minute;
    
//     return Positioned(
//       top: topPosition,
//       left: 0,
//       right: 0,
//       child: Container(
//         height: 2,
//         color: Colors.red,
//       ),
//     );
//   }

//   Widget _buildWeekEventWidget(CalendarEvent event) {
//     final startTime = event.startTime!.toLocal();
//     final topPosition = (startTime.hour * 60.0) + startTime.minute;
    
//     Duration duration = const Duration(hours: 1);
//     if (event.endTime != null) {
//       final endTime = event.endTime!.toLocal();
//       if (_isSameDay(startTime, endTime)) {
//         duration = endTime.difference(startTime);
//       }
//     }
    
//     final height = duration.inMinutes.toDouble().clamp(20.0, double.infinity);
    
//     return Positioned(
//       top: topPosition,
//       left: 2,
//       right: 2,
//       child: GestureDetector(
//         onTap: () => _showEventDetails(event),
//         child: Container(
//           height: height,
//           decoration: BoxDecoration(
//             color: Colors.blue[100],
//             borderRadius: BorderRadius.circular(4),
//             border: Border.all(color: Colors.blue[300]!),
//           ),
//           padding: const EdgeInsets.all(2),
//           child: Text(
//             event.title,
//             style: TextStyle(
//               fontSize: 10,
//               fontWeight: FontWeight.w500,
//               color: Colors.blue[800],
//             ),
//             maxLines: height > 30 ? 2 : 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMonthView() {
//     return PageView.builder(
//       controller: monthPageController,
//       onPageChanged: (index) {
//         final newMonth = DateTime(
//           DateTime.now().year,
//           DateTime.now().month + (index - 500),
//           1,
//         );
//         setState(() {
//           currentMonth = newMonth;
//           selectedDate = newMonth;
//         });
//       },
//       itemBuilder: (context, index) {
//         final monthDate = DateTime(
//           DateTime.now().year,
//           DateTime.now().month + (index - 500),
//           1,
//         );
        
//         return _buildMonthContent(monthDate);
//       },
//     );
//   }

//   Widget _buildMonthContent(DateTime monthDate) {
//     final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
//     final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);
//     final firstDayWeekday = firstDayOfMonth.weekday % 7;
//     final daysInMonth = lastDayOfMonth.day;
    
//     return Column(
//       children: [
//         // Weekday headers
//         Container(
//           padding: const EdgeInsets.symmetric(vertical: 8),
//           decoration: BoxDecoration(
//             border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
//           ),
//           child: Row(
//             children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
//               return Expanded(
//                 child: Text(
//                   day,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//         Expanded(
//           child: GridView.builder(
//             padding: EdgeInsets.zero,
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 7,
//               childAspectRatio: 1.0,
//             ),
//             itemCount: 42, // 6 weeks
//             itemBuilder: (context, index) {
//               final dayNumber = index - firstDayWeekday + 1;
              
//               if (dayNumber <= 0 || dayNumber > daysInMonth) {
//                 return Container(); // Empty cell
//               }
              
//               final date = DateTime(monthDate.year, monthDate.month, dayNumber);
//               final isToday = _isSameDay(date, DateTime.now());
//               final isSelected = _isSameDay(date, selectedDate);
//               final dayEvents = getEventsForDate(date);
              
//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     selectedDate = date;
//                     currentView = CalendarView.day;
//                   });
//                 },
//                 child: Container(
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey[200]!, width: 0.5),
//                     color: isSelected ? Colors.blue[50] : null,
//                   ),
//                   padding: const EdgeInsets.all(4),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                         width: 24,
//                         height: 24,
//                         decoration: BoxDecoration(
//                           color: isToday ? Colors.blue : null,
//                           shape: BoxShape.circle,
//                         ),
//                         alignment: Alignment.center,
//                         child: Text(
//                           '$dayNumber',
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                             color: isToday ? Colors.white : Colors.black87,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       ...dayEvents.take(1).map((event) => Container(
//                         margin: const EdgeInsets.only(bottom: 1),
//                         padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
//                         decoration: BoxDecoration(
//                           color: event.isAllDay ? Colors.blue[100] : Colors.green[100],
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                         child: Text(
//                           event.title,
//                           style: TextStyle(
//                             fontSize: 8,
//                             color: event.isAllDay ? Colors.blue[700] : Colors.green[700],
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       )).toList(),
//                       if (dayEvents.length > 3)
//                         Text(
//                           '+${dayEvents.length - 3} more',
//                           style: TextStyle(
//                             fontSize: 8,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildFloatingActionButton() {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         if (showFabMenu) ...[
//           ScaleTransition(
//             scale: fabAnimation,
//             child: FloatingActionButton(
//               heroTag: "event",
//               mini: true,
//               backgroundColor: Colors.blue,
//               child: const Icon(Icons.event_note, color: Colors.white),
//               onPressed: () {
//                 _toggleFabMenu();
//                 _showCreateEventDialog();
//               },
//             ),
//           ),
//           const SizedBox(height: 16),
//           ScaleTransition(
//             scale: fabAnimation,
//             child: FloatingActionButton(
//               heroTag: "task",
//               mini: true,
//               backgroundColor: Colors.green,
//               child: const Icon(Icons.task_alt, color: Colors.white),
//               onPressed: () {
//                 _toggleFabMenu();
//                 _showCreateTaskDialog();
//               },
//             ),
//           ),
//           const SizedBox(height: 16),
//         ],
//         FloatingActionButton(
//           heroTag: "main",
//           backgroundColor: Colors.indigo,
//           child: AnimatedRotation(
//             turns: showFabMenu ? 0.125 : 0,
//             duration: const Duration(milliseconds: 300),
//             child: const Icon(Icons.add, color: Colors.white),
//           ),
//           onPressed: _toggleFabMenu,
//         ),
//       ],
//     );
//   }

//   void _toggleFabMenu() {
//     setState(() {
//       showFabMenu = !showFabMenu;
//     });
    
//     if (showFabMenu) {
//       fabAnimationController.forward();
//     } else {
//       fabAnimationController.reverse();
//     }
//   }

//   void _showCreateEventDialog() {
//     final titleController = TextEditingController();
//     final descriptionController = TextEditingController();
//     final locationController = TextEditingController();
//     DateTime startDate = selectedDate;
//     TimeOfDay startTime = TimeOfDay.now();
//     DateTime endDate = selectedDate;
//     TimeOfDay endTime = TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);
//     bool isAllDay = false;

//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setDialogState) => AlertDialog(
//           title: const Text('New Event'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: titleController,
//                   decoration: const InputDecoration(
//                     labelText: 'Event title',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: descriptionController,
//                   decoration: const InputDecoration(
//                     labelText: 'Description',
//                     border: OutlineInputBorder(),
//                   ),
//                   maxLines: 3,
//                 ),
//                 const SizedBox(height: 16),
//                 TextField(
//                   controller: locationController,
//                   decoration: const InputDecoration(
//                     labelText: 'Location',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Checkbox(
//                       value: isAllDay,
//                       onChanged: (value) {
//                         setDialogState(() {
//                           isAllDay = value ?? false;
//                         });
//                       },
//                     ),
//                     const Text('All day'),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ListTile(
//                         title: const Text('Start'),
//                         subtitle: Text(
//                           isAllDay
//                               ? DateFormat('MMM d, y').format(startDate)
//                               : '${DateFormat('MMM d, y').format(startDate)} ${startTime.format(context)}',
//                         ),
//                         onTap: () async {
//                           final date = await showDatePicker(
//                             context: context,
//                             initialDate: startDate,
//                             firstDate: DateTime(2020),
//                             lastDate: DateTime(2030),
//                           );
//                           if (date != null) {
//                             setDialogState(() => startDate = date);
                            
//                             if (!isAllDay) {
//                               final time = await showTimePicker(
//                                 context: context,
//                                 initialTime: startTime,
//                               );
//                               if (time != null) {
//                                 setDialogState(() => startTime = time);
//                               }
//                             }
//                           }
//                         },
//                       ),
//                     ),
//                     if (!isAllDay)
//                       Expanded(
//                         child: ListTile(
//                           title: const Text('End'),
//                           subtitle: Text(
//                             '${DateFormat('MMM d, y').format(endDate)} ${endTime.format(context)}',
//                           ),
//                           onTap: () async {
//                             final date = await showDatePicker(
//                               context: context,
//                               initialDate: endDate,
//                               firstDate: DateTime(2020),
//                               lastDate: DateTime(2030),
//                             );
//                             if (date != null) {
//                               setDialogState(() => endDate = date);
                              
//                               final time = await showTimePicker(
//                                 context: context,
//                                 initialTime: endTime,
//                               );
//                               if (time != null) {
//                                 setDialogState(() => endTime = time);
//                               }
//                             }
//                           },
//                         ),
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('CANCEL'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 if (titleController.text.isNotEmpty) {
//                   _createEvent(
//                     summary: titleController.text,
//                     description: descriptionController.text,
//                     location: locationController.text,
//                     startDate: startDate,
//                     startTime: startTime,
//                     endDate: endDate,
//                     endTime: endTime,
//                     isAllDay: isAllDay,
//                   );
//                   Navigator.pop(context);
//                 }
//               },
//               child: const Text('SAVE'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showCreateTaskDialog() {
//     final titleController = TextEditingController();
//     DateTime dueDate = selectedDate;

//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setDialogState) => AlertDialog(
//           title: const Text('New Task'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: titleController,
//                 decoration: const InputDecoration(
//                   labelText: 'Task title',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               ListTile(
//                 title: const Text('Due date'),
//                 subtitle: Text(DateFormat('MMM d, y').format(dueDate)),
//                 onTap: () async {
//                   final date = await showDatePicker(
//                     context: context,
//                     initialDate: dueDate,
//                     firstDate: DateTime.now(),
//                     lastDate: DateTime(2030),
//                   );
//                   if (date != null) {
//                     setDialogState(() => dueDate = date);
//                   }
//                 },
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('CANCEL'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 if (titleController.text.isNotEmpty) {
//                   _createTask(
//                     title: titleController.text,
//                     dueDate: dueDate,
//                   );
//                   Navigator.pop(context);
//                 }
//               },
//               child: const Text('SAVE'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _createEvent({
//     required String summary,
//     required String description,
//     required String location,
//     required DateTime startDate,
//     required TimeOfDay startTime,
//     required DateTime endDate,
//     required TimeOfDay endTime,
//     required bool isAllDay,
//   }) async {
//     try {
//       final startDateTime = isAllDay
//           ? startDate
//           : DateTime(startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute);
      
//       final endDateTime = isAllDay
//           ? endDate.add(const Duration(days: 1))
//           : DateTime(endDate.year, endDate.month, endDate.day, endTime.hour, endTime.minute);

//       final apiKey = dotenv.env['GOOGLE_CALENDAR_API_KEY'];
//       if (apiKey == null || apiKey.isEmpty) {
//         throw Exception("Google Calendar API key not found");
//       }

//       final Map<String, dynamic> eventBody = {
//         'summary': summary,
//         'description': description,
//         'location': location,
//       };

//       if (isAllDay) {
//         eventBody['start'] = {
//           'date': startDateTime.toIso8601String().split('T')[0],
//         };
//         eventBody['end'] = {
//           'date': endDateTime.toIso8601String().split('T')[0],
//         };
//       } else {
//         eventBody['start'] = {
//           'dateTime': startDateTime.toIso8601String(),
//           'timeZone': DateTime.now().timeZoneName,
//         };
//         eventBody['end'] = {
//           'dateTime': endDateTime.toIso8601String(),
//           'timeZone': DateTime.now().timeZoneName,
//         };
//       }
//       final calendarId = 'dhruvviveksharma@gmail.com';
      
//       final url = 'https://www.googleapis.com/calendar/v3/calendars/$calendarId/events?key=$apiKey';
//       // Remove the event data from the URL and include it in the request body instead.

//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode(eventBody),
//       );
      
//       if (response.statusCode == 200) {
//         final createdEvent = jsonDecode(response.body);
        
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Event "$summary" created successfully'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       } else {
//         final errorData = jsonDecode(response.body);
//         throw Exception("API Error: ${response.statusCode} - ${errorData['error']['message']}");
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to create event: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   void _createTask({
//     required String title,
//     required DateTime dueDate,
//   }) {
//     // In a real app, this would make an API call to create the task
//     final newTask = CalendarEvent(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       title: '📋 $title',
//       description: 'Task',
//       location: '',
//       startTime: dueDate,
//       endTime: dueDate,
//       isAllDay: true,
//     );

//     setState(() {
//       events.add(newTask);
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Task "$title" created'),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   void _showEventDetails(CalendarEvent event) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: MediaQuery.of(context).size.height * 0.7,
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//         ),
//         child: Column(
//           children: [
//             Container(
//               margin: const EdgeInsets.symmetric(vertical: 8),
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           width: 4,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: Colors.indigo,
//                             borderRadius: BorderRadius.circular(2),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 event.title,
//                                 style: const TextStyle(
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               if (event.startTime != null) ...[
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   event.isAllDay
//                                       ? DateFormat('EEEE, MMMM d, y').format(event.startTime!)
//                                       : '${DateFormat('EEEE, MMMM d, y').format(event.startTime!)} • ${DateFormat('h:mm a').format(event.startTime!.toLocal())}${event.endTime != null ? ' - ${DateFormat('h:mm a').format(event.endTime!.toLocal())}' : ''}',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ],
//                           ),
//                         ),
//                         PopupMenuButton<String>(
//                           onSelected: (value) => _handleEventAction(value, event),
//                           itemBuilder: (context) => [
//                             const PopupMenuItem(value: 'edit', child: Text('Edit')),
//                             const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
//                             const PopupMenuItem(value: 'delete', child: Text('Delete')),
//                           ],
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 32),
//                     if (event.description.isNotEmpty) ...[
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Icon(Icons.description, size: 20),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: Text(
//                               event.description,
//                               style: const TextStyle(fontSize: 16),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 24),
//                     ],
//                     if (event.location.isNotEmpty) ...[
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Icon(Icons.location_on, size: 20),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: Text(
//                               event.location,
//                               style: const TextStyle(fontSize: 16),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 24),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _handleEventAction(String action, CalendarEvent event) {
//     switch (action) {
//       case 'edit':
//         _showEditEventDialog(event);
//         break;
//       case 'duplicate':
//         _duplicateEvent(event);
//         break;
//       case 'delete':
//         _showDeleteEventDialog(event);
//         break;
//     }
//   }

//   void _showEditEventDialog(CalendarEvent event) {
//     final titleController = TextEditingController(text: event.title);
//     final descriptionController = TextEditingController(text: event.description);
//     final locationController = TextEditingController(text: event.location);
    
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Edit Event'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: titleController,
//               decoration: const InputDecoration(
//                 labelText: 'Event title',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: descriptionController,
//               decoration: const InputDecoration(
//                 labelText: 'Description',
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 3,
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: locationController,
//               decoration: const InputDecoration(
//                 labelText: 'Location',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('CANCEL'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               if (titleController.text.isNotEmpty) {
//                 _updateEvent(event, titleController.text, descriptionController.text, locationController.text);
//                 Navigator.pop(context);
//               }
//             },
//             child: const Text('SAVE'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _duplicateEvent(CalendarEvent event) {
//     final duplicatedEvent = CalendarEvent(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       title: '${event.title} (Copy)',
//       description: event.description,
//       location: event.location,
//       startTime: event.startTime,
//       endTime: event.endTime,
//       isAllDay: event.isAllDay,
//     );

//     setState(() {
//       events.add(duplicatedEvent);
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Event duplicated'),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   void _showDeleteEventDialog(CalendarEvent event) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Event'),
//         content: Text('Are you sure you want to delete "${event.title}"?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('CANCEL'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               _deleteEvent(event);
//               Navigator.pop(context);
//               Navigator.pop(context); // Close event details
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: const Text('DELETE'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _updateEvent(CalendarEvent event, String title, String description, String location) {
//     final index = events.indexWhere((e) => e.id == event.id);
//     if (index != -1) {
//       setState(() {
//         events[index] = CalendarEvent(
//           id: event.id,
//           title: title,
//           description: description,
//           location: location,
//           startTime: event.startTime,
//           endTime: event.endTime,
//           isAllDay: event.isAllDay,
//         );
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Event updated'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   }

//   void _deleteEvent(CalendarEvent event) {
//     setState(() {
//       events.removeWhere((e) => e.id == event.id);
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Event "${event.title}" deleted'),
//         backgroundColor: Colors.red,
//         action: SnackBarAction(
//           label: 'UNDO',
//           textColor: Colors.white,
//           onPressed: () {
//             setState(() {
//               events.add(event);
//             });
//           },
//         ),
//       ),
//     );
//   }

//   void _showSearchDialog() {
//     final searchController = TextEditingController();
//     List<CalendarEvent> searchResults = [];

//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setSearchState) => AlertDialog(
//           title: const Text('Search Events'),
//           content: SizedBox(
//             width: double.maxFinite,
//             height: 400,
//             child: Column(
//               children: [
//                 TextField(
//                   controller: searchController,
//                   decoration: const InputDecoration(
//                     hintText: 'Search events...',
//                     prefixIcon: Icon(Icons.search, color: Colors.indigo),
//                     border: OutlineInputBorder(),
//                   ),
//                   onChanged: (query) {
//                     setSearchState(() {
//                       if (query.isEmpty) {
//                         searchResults = [];
//                       } else {
//                         searchResults = events
//                             .where((event) =>
//                                 event.title.toLowerCase().contains(query.toLowerCase()) ||
//                                 event.description.toLowerCase().contains(query.toLowerCase()) ||
//                                 event.location.toLowerCase().contains(query.toLowerCase()))
//                             .toList();
//                       }
//                     });
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: searchResults.length,
//                     itemBuilder: (context, index) {
//                       final event = searchResults[index];
//                       return ListTile(
//                         title: Text(event.title),
//                         subtitle: Text(
//                           event.startTime != null
//                               ? DateFormat('MMM d, y').format(event.startTime!)
//                               : '',
//                         ),
//                         onTap: () {
//                           Navigator.pop(context);
//                           _showEventDetails(event);
//                         },
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('CLOSE'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showSettingsDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Settings'),
//         content: const Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: Icon(Icons.color_lens),
//               title: Text('Theme'),
//               subtitle: Text('Light'),
//             ),
//             ListTile(
//               leading: Icon(Icons.notifications),
//               title: Text('Notifications'),
//               subtitle: Text('Enabled'),
//             ),
//             ListTile(
//               leading: Icon(Icons.language),
//               title: Text('Language'),
//               subtitle: Text('English'),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('CLOSE'),
//           ),
//         ],
//       ),
//     );
//   }

//   bool _isSameDay(DateTime date1, DateTime date2) {
//     return date1.year == date2.year &&
//         date1.month == date2.month &&
//         date1.day == date2.day;
//   }

//   Widget _buildDrawer() {
//     return Drawer(
//       child: Column(
//         children: [
//           const DrawerHeader(
//             decoration: BoxDecoration(color: Colors.blue),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 Text(
//                   'Calendar',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'dhruvviveksharma@gmail.com',
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.event),
//             title: const Text('Events'),
//             onTap: () {
//               Navigator.pop(context);
//               setState(() => currentView = CalendarView.schedule);
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.task_alt),
//             title: const Text('Tasks'),
//             onTap: () {
//               Navigator.pop(context);
//               // Filter to show only tasks
//             },
//           ),
//           const Divider(),
//           ListTile(
//             leading: const Icon(Icons.settings),
//             title: const Text('Settings'),
//             onTap: () {
//               Navigator.pop(context);
//               _showSettingsDialog();
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.help),
//             title: const Text('Help & feedback'),
//             onTap: () {
//               Navigator.pop(context);
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: Colors.grey[50],
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(120),
//         child: _buildAppBar(),
//       ),
//       drawer: _buildDrawer(),
//       body: isLoading
//           ? const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(color: Colors.blue),
//                   SizedBox(height: 16),
//                   Text('Loading events...', style: TextStyle(color: Colors.grey)),
//                 ],
//               ),
//             )
//           : () {
//               switch (currentView) {
//                 case CalendarView.schedule:
//                   return _buildScheduleView();
//                 case CalendarView.day:
//                   return _buildDayView();
//                 case CalendarView.week:
//                   return _buildWeekView();
//                 case CalendarView.month:
//                   return _buildMonthView();
//               }
//             }(),
//       floatingActionButton: _buildFloatingActionButton(),
//     );
//   }
// }

// class CalendarEvent {
//   final String id;
//   final String title;
//   final String description;
//   final String location;
//   final DateTime? startTime;
//   final DateTime? endTime;
//   final bool isAllDay;

//   CalendarEvent({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.location,
//     this.startTime,
//     this.endTime,
//     required this.isAllDay,
//   });

//   factory CalendarEvent.fromJson(Map<String, dynamic> json) {
//     DateTime? parseDateTime(dynamic dateTimeData) {
//       if (dateTimeData == null) return null;
      
//       try {
//         if (dateTimeData is Map) {
//           if (dateTimeData['dateTime'] != null) {
//             return DateTime.parse(dateTimeData['dateTime']);
//           }
//           else if (dateTimeData['date'] != null) {
//             return DateTime.parse(dateTimeData['date']);
//           }
//         }
//       } catch (e) {
//         debugPrint('Error parsing date: $e');
//       }
//       return null;
//     }

//     final startData = json['start'];
//     final endData = json['end'];
//     final isAllDay = startData != null && startData['date'] != null;

//     return CalendarEvent(
//       id: json['id']?.toString() ?? '',
//       title: json['summary']?.toString() ?? 'Untitled Event',
//       description: json['description']?.toString() ?? '',
//       location: json['location']?.toString() ?? '',
//       startTime: parseDateTime(startData),
//       endTime: parseDateTime(endData),
//       isAllDay: isAllDay,
//     );
//   }

//   @override
//   String toString() {
//     return 'CalendarEvent(id: $id, title: $title, startTime: $startTime, isAllDay: $isAllDay)';
//   }
// }


// // First, add these dependencies to your pubspec.yaml:
// /*
// dependencies:
//   google_sign_in: ^6.1.5
//   googleapis: ^11.4.0
//   googleapis_auth: ^1.4.1
//   extension_google_sign_in_as_googleapis_auth: ^2.0.12
// */

// // 1. Create a new file: lib/services/google_auth_service.dart


// // 2. Updated Calendar Page with OAuth 2.0
// class _CalendarPageState extends State<CalendarPage> with TickerProviderStateMixin {
//   List<CalendarEvent> events = [];
//   bool isLoading = true;
//   bool isSignedIn = false;
//   CalendarView currentView = CalendarView.month;
//   DateTime selectedDate = DateTime.now();
//   DateTime currentMonth = DateTime.now();
//   late PageController monthPageController;
//   late PageController weekPageController;
//   late PageController dayPageController;
//   late AnimationController fabAnimationController;
//   late Animation<double> fabAnimation;
//   bool showFabMenu = false;
  
//   CalendarApi? _calendarApi;
//   String? userEmail;
  
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   @override
//   void initState() {
//     super.initState();
//     monthPageController = PageController(initialPage: 500);
//     weekPageController = PageController(initialPage: 500);
//     dayPageController = PageController(initialPage: 500);
//     fabAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: fabAnimationController, curve: Curves.elasticOut),
//     );
    
//     _initializeAuth();
//     _listenToAuthChanges();
//   }

//   void _initializeAuth() async {
//     // Check if user is already signed in
//     isSignedIn = GoogleAuthService.isSignedIn;
//     if (isSignedIn) {
//       userEmail = GoogleAuthService.currentUser?.email;
//       await _initializeCalendarApi();
//       await fetchEvents();
//     } else {
//       setState(() => isLoading = false);
//     }
//   }

//   void _listenToAuthChanges() {
//     GoogleAuthService.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
//       setState(() {
//         isSignedIn = account != null;
//         userEmail = account?.email;
//       });
      
//       if (account != null) {
//         _initializeCalendarApi();
//         fetchEvents();
//       } else {
//         _calendarApi = null;
//         events.clear();
//       }
//     });
//   }

//   Future<void> _initializeCalendarApi() async {
//     final authClient = await GoogleAuthService.getAuthClient();
//     if (authClient != null) {
//       _calendarApi = CalendarApi(authClient);
//     }
//   }

//   @override
//   void dispose() {
//     monthPageController.dispose();
//     weekPageController.dispose();
//     dayPageController.dispose();
//     fabAnimationController.dispose();
//     super.dispose();
//   }

//   Future<void> _signIn() async {
//     setState(() => isLoading = true);
    
//     final account = await GoogleAuthService.signIn();
//     if (account != null) {
//       setState(() {
//         isSignedIn = true;
//         userEmail = account.email;
//       });
//       await _initializeCalendarApi();
//       await fetchEvents();
//     } else {
//       setState(() => isLoading = false);
//       _showErrorSnackBar('Failed to sign in');
//     }
//   }

//   Future<void> _signOut() async {
//     await GoogleAuthService.signOut();
//     setState(() {
//       isSignedIn = false;
//       userEmail = null;
//       events.clear();
//       _calendarApi = null;
//     });
//   }

//   Future<void> fetchEvents() async {
//     if (!isSignedIn || _calendarApi == null) return;
    
//     setState(() => isLoading = true);
    
//     try {
//       final now = DateTime.now();
//       final timeMin = DateTime(now.year - 1, 1, 1).toUtc();
//       final timeMax = DateTime(now.year + 1, 12, 31).toUtc();
      
//       final eventsResult = await _calendarApi!.events.list(
//         'primary', // Use primary calendar
//         orderBy: 'startTime',
//         timeMin: timeMin,
//         timeMax: timeMax,
//         singleEvents: true,
//         maxResults: 1000,
//       );
      
//       final eventItems = eventsResult.items ?? [];
      
//       setState(() {
//         events = eventItems
//             .map((item) => CalendarEvent.fromGoogleEvent(item))
//             .where((event) => event.title.isNotEmpty)
//             .toList();
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() => isLoading = false);
//       _showErrorSnackBar('Error: $e');
//     }
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red[600],
//         action: SnackBarAction(
//           label: 'RETRY',
//           textColor: Colors.white,
//           onPressed: fetchEvents,
//         ),
//       ),
//     );
//   }

//   // Sign-in screen widget
//   Widget _buildSignInScreen() {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(32.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.calendar_today,
//                 size: 80,
//                 color: Colors.blue[400],
//               ),
//               const SizedBox(height: 32),
//               Text(
//                 'Welcome to Calendar',
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey[800],
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Sign in with your Google account to manage your calendar events',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               const SizedBox(height: 48),
//               isLoading 
//                 ? const CircularProgressIndicator()
//                 : ElevatedButton.icon(
//                     onPressed: _signIn,
//                     icon: Image.network(
//                       'https://developers.google.com/identity/images/g-logo.png',
//                       height: 20,
//                       width: 20,
//                     ),
//                     label: const Text('Sign in with Google'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.white,
//                       foregroundColor: Colors.black87,
//                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         side: BorderSide(color: Colors.grey[300]!),
//                       ),
//                     ),
//                   ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Update the create event method to use Calendar API
//   Future<void> _createEvent({
//     required String summary,
//     required String description,
//     required String location,
//     required DateTime startDate,
//     required TimeOfDay startTime,
//     required DateTime endDate,
//     required TimeOfDay endTime,
//     required bool isAllDay,
//   }) async {
//     if (_calendarApi == null) {
//       _showErrorSnackBar('Not authenticated');
//       return;
//     }

//     try {
//       final startDateTime = isAllDay
//           ? startDate
//           : DateTime(startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute);
      
//       final endDateTime = isAllDay
//           ? endDate.add(const Duration(days: 1))
//           : DateTime(endDate.year, endDate.month, endDate.day, endTime.hour, endTime.minute);

//       final event = Event()
//         ..summary = summary
//         ..description = description
//         ..location = location;

//       if (isAllDay) {
//         event.start = EventDateTime()
//           ..date = DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
//         event.end = EventDateTime()
//           ..date = DateTime(endDateTime.year, endDateTime.month, endDateTime.day);
//       } else {
//         event.start = EventDateTime()
//           ..dateTime = startDateTime.toUtc()
//           ..timeZone = DateTime.now().timeZoneName;
//         event.end = EventDateTime()
//           ..dateTime = endDateTime.toUtc()
//           ..timeZone = DateTime.now().timeZoneName;
//       }

//       final createdEvent = await _calendarApi!.events.insert(event, 'primary');
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Event "$summary" created successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         // Refresh events
//         fetchEvents();
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to create event: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // Update delete event method
//   Future<void> _deleteEventFromGoogle(CalendarEvent event) async {
//     if (_calendarApi == null) {
//       _showErrorSnackBar('Not authenticated');
//       return;
//     }

//     try {
//       await _calendarApi!.events.delete('primary', event.id);
      
//       setState(() {
//         events.removeWhere((e) => e.id == event.id);
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Event "${event.title}" deleted'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to delete event: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // Update the app bar to show sign out option
//   Widget _buildAppBar() {
//     String title = '';
//     switch (currentView) {
//       case CalendarView.schedule:
//         title = 'Schedule';
//         break;
//       case CalendarView.day:
//         title = DateFormat('EEEE, MMM d').format(selectedDate);
//         break;
//       case CalendarView.week:
//         final weekStart = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
//         final weekEnd = weekStart.add(const Duration(days: 6));
//         title = '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}';
//         break;
//       case CalendarView.month:
//         title = DateFormat('MMMM y').format(currentMonth);
//         break;
//     }

//     return AppBar(
//       backgroundColor: Colors.orange[400],
//       elevation: 0,
//       leading: IconButton(
//         icon: const Icon(Icons.menu, color: Colors.black87),
//         onPressed: () => _scaffoldKey.currentState?.openDrawer(),
//       ),
//       title: Row(
//         children: [
//           if (currentView != CalendarView.schedule)
//             IconButton(
//               icon: Icon(Icons.today, color: Colors.blue[900], size: 20),
//               onPressed: () {
//                 setState(() {
//                   selectedDate = DateTime.now();
//                   currentMonth = DateTime.now();
//                 });
//                 _jumpToToday();
//               },
//             ),
//           Expanded(
//             child: Text(
//               title,
//               style: const TextStyle(
//                 color: Colors.black87,
//                 fontSize: 20,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//       actions: [
//         IconButton(
//           icon: Icon(Icons.home, color: Colors.blue[900]),
//           onPressed: () => Navigator.pop(context),
//         ),
//         if (isSignedIn) ...[
//           IconButton(
//             icon: const Icon(Icons.search, color: Colors.black54),
//             onPressed: _showSearchDialog,
//           ),
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.more_vert, color: Colors.black54),
//             onSelected: (value) {
//               switch (value) {
//                 case 'refresh':
//                   fetchEvents();
//                   break;
//                 case 'signout':
//                   _signOut();
//                   break;
//                 case 'settings':
//                   _showSettingsDialog();
//                   break;
//               }
//             },
//             itemBuilder: (context) => [
//               const PopupMenuItem(
//                 value: 'refresh',
//                 child: Row(
//                   children: [
//                     Icon(Icons.refresh, size: 20),
//                     SizedBox(width: 12),
//                     Text('Refresh'),
//                   ],
//                 ),
//               ),
//               const PopupMenuItem(
//                 value: 'signout',
//                 child: Row(
//                   children: [
//                     Icon(Icons.logout, size: 20),
//                     SizedBox(width: 12),
//                     Text('Sign Out'),
//                   ],
//                 ),
//               ),
//               const PopupMenuItem(
//                 value: 'settings',
//                 child: Row(
//                   children: [
//                     Icon(Icons.settings, size: 20),
//                     SizedBox(width: 12),
//                     Text('Settings'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ],
//       bottom: isSignedIn ? PreferredSize(
//         preferredSize: const Size.fromHeight(60),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Row(
//             children: [
//               _buildViewButton('S', CalendarView.schedule),
//               _buildViewButton('D', CalendarView.day),
//               _buildViewButton('W', CalendarView.week),
//               _buildViewButton('M', CalendarView.month),
//               const Spacer(),
//               if (currentView != CalendarView.schedule) ...[
//                 IconButton(
//                   icon: const Icon(Icons.chevron_left, color: Colors.black54),
//                   onPressed: _navigatePrevious,
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.chevron_right, color: Colors.black54),
//                   onPressed: _navigateNext,
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ) : null,
//     );
//   }

//   // Update drawer to show user info
//   Widget _buildDrawer() {
//     return Drawer(
//       child: Column(
//         children: [
//           DrawerHeader(
//             decoration: const BoxDecoration(color: Colors.blue),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 const Text(
//                   'Calendar',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   isSignedIn ? (userEmail ?? 'Signed In') : 'Not signed in',
//                   style: const TextStyle(
//                     color: Colors.white70,
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (isSignedIn) ...[
//             ListTile(
//               leading: const Icon(Icons.event),
//               title: const Text('Events'),
//               onTap: () {
//                 Navigator.pop(context);
//                 setState(() => currentView = CalendarView.schedule);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.task_alt),
//               title: const Text('Tasks'),
//               onTap: () {
//                 Navigator.pop(context);
//               },
//             ),
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.settings),
//               title: const Text('Settings'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showSettingsDialog();
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.logout),
//               title: const Text('Sign Out'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _signOut();
//               },
//             ),
//           ] else
//             ListTile(
//               leading: const Icon(Icons.login),
//               title: const Text('Sign In'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _signIn();
//               },
//             ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Show sign-in screen if not authenticated
//     if (!isSignedIn) {
//       return _buildSignInScreen();
//     }

//     // Rest of your existing build method for the authenticated state
//     return Scaffold(
//       key: _scaffoldKey,
//       backgroundColor: Colors.grey[50],
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(120),
//         child: _buildAppBar(),
//       ),
//       drawer: _buildDrawer(),
//       body: isLoading
//           ? const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(color: Colors.blue),
//                   SizedBox(height: 16),
//                   Text('Loading events...', style: TextStyle(color: Colors.grey)),
//                 ],
//               ),
//             )
//           : () {
//               switch (currentView) {
//                 case CalendarView.schedule:
//                   return _buildScheduleView();
//                 case CalendarView.day:
//                   return _buildDayView();
//                 case CalendarView.week:
//                   return _buildWeekView();
//                 case CalendarView.month:
//                   return _buildMonthView();
//               }
//             }(),
//       floatingActionButton: isSignedIn ? _buildFloatingActionButton() : null,
//     );
//   }

//   // Add the rest of your existing methods here (they remain mostly the same)
//   // Just make sure to update any event operations to use the Google Calendar API
  
//   List<CalendarEvent> getEventsForDate(DateTime date) {
//     return events.where((event) {
//       if (event.startTime == null) return false;
//       final eventDate = event.startTime!;
      
//       if (event.isAllDay) {
//         return eventDate.year == date.year &&
//             eventDate.month == date.month &&
//             eventDate.day == date.day;
//       }
      
//       final localEventDate = eventDate.toLocal();
//       return localEventDate.year == date.year &&
//           localEventDate.month == date.month &&
//           localEventDate.day == date.day;
//     }).toList()..sort((a, b) {
//       if (a.startTime == null || b.startTime == null) return 0;
//       return a.startTime!.compareTo(b.startTime!);
//     });
//   }

//   // [Include all your other existing methods here - _buildScheduleView, _buildDayView, etc.]
//   // They should work the same way, just make sure event operations use the Calendar API
// }

// // Updated CalendarEvent class to work with Google Calendar API
// class CalendarEvent {
//   final String id;
//   final String title;
//   final String description;
//   final String location;
//   final DateTime? startTime;
//   final DateTime? endTime;
//   final bool isAllDay;

//   CalendarEvent({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.location,
//     this.startTime,
//     this.endTime,
//     required this.isAllDay,
//   });

//   factory CalendarEvent.fromGoogleEvent(Event event) {
//     DateTime? parseDateTime(EventDateTime? eventDateTime) {
//       if (eventDateTime == null) return null;
      
//       try {
//         if (eventDateTime.dateTime != null) {
//           return eventDateTime.dateTime!.toLocal();
//         } else if (eventDateTime.date != null) {
//           return eventDateTime.date!;
//         }
//       } catch (e) {
//         debugPrint('Error parsing date: $e');
//       }
//       return null;
//     }

//     final isAllDay = event.start?.date != null;

//     return CalendarEvent(
//       id: event.id ?? '',
//       title: event.summary ?? 'Untitled Event',
//       description: event.description ?? '',
//       location: event.location ?? '',
//       startTime: parseDateTime(event.start),
//       endTime: parseDateTime(event.end),
//       isAllDay: isAllDay,
//     );
//   }

//   @override
//   String toString() {
//     return 'CalendarEvent(id: $id, title: $title, startTime: $startTime, isAllDay: $isAllDay)';
//   }
// }