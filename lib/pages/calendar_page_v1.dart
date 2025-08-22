import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

enum CalendarView {day, week, month, year }

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<CalendarEvent> events = [];
  bool isLoading = true;
  CalendarView currentView = CalendarView.month;
  DateTime selectedDate = DateTime.now();
  DateTime currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    setState(() => isLoading = true);
    
    try {
      final apiKey = dotenv.env['GOOGLE_CALENDAR_API'];
      if (apiKey == null) {
        throw Exception('Google Calendar API key not found in .env file');
      }
      
      final calendarId = 'dhruvviveksharma@gmail.com';
      final now = DateTime.now();
      final timeMin = DateTime(now.year - 1, 1, 1).toUtc().toIso8601String();
      final timeMax = DateTime(now.year + 1, 12, 31).toUtc().toIso8601String();
      
      final url = 'https://www.googleapis.com/calendar/v3/calendars/$calendarId/events'
          '?key=$apiKey'
          '&orderBy=startTime'
          '&timeMin=$timeMin'
          '&timeMax=$timeMax'
          '&singleEvents=true'
          '&maxResults=1000';
          
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final eventItems = data['items'] as List? ?? [];
        
        setState(() {
          events = eventItems
              .map((item) => CalendarEvent.fromJson(item))
              .where((event) => event.title.isNotEmpty)
              .toList();
          isLoading = false;
        });
        
        debugPrint('Successfully loaded ${events.length} events');
      } else if (response.statusCode == 403) {
        throw Exception('API access denied. Please check your API key permissions.');
      } else if (response.statusCode == 404) {
        throw Exception('Calendar not found. Please check the calendar ID.');
      } else {
        throw Exception('Failed to load events: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      showErrorDialog('Error fetching calendar events: $e');
      debugPrint('Calendar fetch error: $e');
    }
  }

  void showErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Error',
          style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: TextStyle(color: Colors.grey[700])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.teal)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              fetchEvents(); // Retry
            },
            child: Text('Retry', style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  List<CalendarEvent> getEventsForDate(DateTime date) {
    return events.where((event) {
      if (event.startTime == null) return false;
      final eventDate = event.startTime!;
      
      // Handle all-day events
      if (event.isAllDay) {
        return eventDate.year == date.year &&
            eventDate.month == date.month &&
            eventDate.day == date.day;
      }
      
      // Handle timed events - convert to local time for comparison
      final localEventDate = eventDate.toLocal();
      return localEventDate.year == date.year &&
          localEventDate.month == date.month &&
          localEventDate.day == date.day;
    }).toList()..sort((a, b) {
      if (a.startTime == null || b.startTime == null) return 0;
      return a.startTime!.compareTo(b.startTime!);
    });
  }

  List<CalendarEvent> getEventsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
    return events.where((event) {
      if (event.startTime == null) return false;
      final eventDate = event.isAllDay ? event.startTime! : event.startTime!.toLocal();
      return eventDate.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
          eventDate.isBefore(weekEnd.add(const Duration(seconds: 1)));
    }).toList()..sort((a, b) {
      if (a.startTime == null || b.startTime == null) return 0;
      return a.startTime!.compareTo(b.startTime!);
    });
  }

  List<CalendarEvent> getEventsForMonth(DateTime month) {
    return events.where((event) {
      if (event.startTime == null) return false;
      final eventDate = event.isAllDay ? event.startTime! : event.startTime!.toLocal();
      return eventDate.year == month.year && eventDate.month == month.month;
    }).toList()..sort((a, b) {
      if (a.startTime == null || b.startTime == null) return 0;
      return a.startTime!.compareTo(b.startTime!);
    });
  }

  List<CalendarEvent> getEventsForYear(DateTime year) {
    return events.where((event) {
      if (event.startTime == null) return false;
      final eventDate = event.isAllDay ? event.startTime! : event.startTime!.toLocal();
      return eventDate.year == year.year;
    }).toList()..sort((a, b) {
      if (a.startTime == null || b.startTime == null) return 0;
      return a.startTime!.compareTo(b.startTime!);
    });
  }

  Widget buildViewSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: CalendarView.values.map((view) {
          final isSelected = currentView == view;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => currentView = view),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.teal[400] : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  view.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildNavigationHeader() {
    String title;
    switch (currentView) {
      case CalendarView.day:
        title = DateFormat('EEEE, MMMM d, y').format(selectedDate);
        break;
      case CalendarView.week:
        final weekStart = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        title = '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, y').format(weekEnd)}';
        break;
      case CalendarView.month:
        title = DateFormat('MMMM y').format(currentMonth);
        break;
      case CalendarView.year:
        title = DateFormat('y').format(selectedDate);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                switch (currentView) {
                  case CalendarView.day:
                    selectedDate = selectedDate.subtract(const Duration(days: 1));
                    break;
                  case CalendarView.week:
                    selectedDate = selectedDate.subtract(const Duration(days: 7));
                    break;
                  case CalendarView.month:
                    currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
                    break;
                  case CalendarView.year:
                    selectedDate = DateTime(selectedDate.year - 1, selectedDate.month, selectedDate.day);
                    break;
                }
              });
            },
            icon: Icon(Icons.chevron_left, color: Colors.teal[400]),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                switch (currentView) {
                  case CalendarView.day:
                    selectedDate = selectedDate.add(const Duration(days: 1));
                    break;
                  case CalendarView.week:
                    selectedDate = selectedDate.add(const Duration(days: 7));
                    break;
                  case CalendarView.month:
                    currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
                    break;
                  case CalendarView.year:
                    selectedDate = DateTime(selectedDate.year + 1, selectedDate.month, selectedDate.day);
                    break;
                }
              });
            },
            icon: Icon(Icons.chevron_right, color: Colors.teal[400]),
          ),
        ],
      ),
    );
  }

  Widget buildDayView() {
    final dayEvents = getEventsForDate(selectedDate);
    
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.teal[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('d').format(selectedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('EEE').format(selectedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Events Today',
                      style: TextStyle(
                        color: Colors.indigo[900],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${dayEvents.length} event${dayEvents.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: dayEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No events today',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayEvents.length,
                  itemBuilder: (context, index) {
                    return buildEventCard(dayEvents[index]);
                  },
                ),
        ),
      ],
    );
  }

Widget buildDayColumn(DateTime day) {
    final dayEvents = getEventsForDate(day);
    final timedEvents = dayEvents.where((e) => !e.isAllDay).toList();
    final allDayEvents = dayEvents.where((e) => e.isAllDay).toList();
    
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Column(
          children: [
            // All-day events section
            if (allDayEvents.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Column(
                  children: allDayEvents.take(3).map((event) => Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange[300]!, width: 1),
                    ),
                    child: Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )).toList(),
                ),
              ),
            
            // Hourly grid with timed events
            Stack(
              children: [
                // Hour grid lines
                Column(
                  children: List.generate(24, (hour) {
                    return Container(
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey[100]!, width: 1),
                        ),
                      ),
                    );
                  }),
                ),
                
                // Timed events positioned by hour
                ...timedEvents.map((event) {
                  if (event.startTime == null) return const SizedBox();
                  
                  final startTime = event.startTime!.toLocal();
                  final startHour = startTime.hour;
                  final startMinute = startTime.minute;
                  final topPosition = (startHour * 60.0) + (startMinute * 60.0 / 60.0);
                  
                  Duration duration = const Duration(hours: 1);
                  if (event.endTime != null) {
                    final endTime = event.endTime!.toLocal();
                    if (endTime.day == startTime.day) {
                      duration = endTime.difference(startTime);
                    }
                  }
                  
                  final height = (duration.inMinutes * 60.0 / 60.0).clamp(20.0, 300.0);
                  
                  return Positioned(
                    top: topPosition,
                    left: 2,
                    right: 2,
                    child: Container(
                      height: height,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: Colors.teal[100],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.teal[300]!, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('h:mm').format(startTime),
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.teal[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (height > 30)
                              Expanded(
                                child: Text(
                                  event.title,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.teal[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildWeekView() {
    final weekStart = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final weekEvents = getEventsForWeek(weekStart);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: List.generate(7, (index) {
                  final day = weekStart.add(Duration(days: index));
                  final today = DateTime.now();
                  final isToday = day.year == today.year &&
                      day.month == today.month &&
                      day.day == today.day;
                  final dayEvents = getEventsForDate(day);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        selectedDate = day;
                        currentView = CalendarView.day;
                      }),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isToday ? Colors.teal[400] : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('EEE').format(day),
                              style: TextStyle(
                                color: isToday ? Colors.white : Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              day.day.toString(),
                              style: TextStyle(
                                color: isToday ? Colors.white : Colors.indigo[900],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (dayEvents.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isToday ? Colors.white : Colors.teal[400],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        Expanded(
          child: weekEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No events this week',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: weekEvents.length,
                  itemBuilder: (context, index) {
                    return buildEventCard(weekEvents[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget buildMonthView() {
    final monthEvents = getEventsForMonth(currentMonth);
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final startDate = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    final endDate = lastDay.add(Duration(days: 7 - lastDay.weekday));

    return Column(
      children: [
        // Calendar Grid
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Weekday headers
              Row(
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map((day) => Expanded(
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              // Calendar days
              ...List.generate(
                (endDate.difference(startDate).inDays / 7).ceil(),
                (weekIndex) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: List.generate(7, (dayIndex) {
                        final date = startDate.add(Duration(days: weekIndex * 7 + dayIndex));
                        final isCurrentMonth = date.month == currentMonth.month;
                        final today = DateTime.now();
                        final isToday = date.year == today.year &&
                            date.month == today.month &&
                            date.day == today.day;
                        final dayEvents = getEventsForDate(date);

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              selectedDate = date;
                              currentView = CalendarView.day;
                            }),
                            child: Container(
                              height: 40,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: isToday ? Colors.teal[400] : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    date.day.toString(),
                                    style: TextStyle(
                                      color: isToday
                                          ? Colors.white
                                          : isCurrentMonth
                                              ? Colors.indigo[900]
                                              : Colors.grey[400],
                                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (dayEvents.isNotEmpty)
                                    Positioned(
                                      bottom: 6,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: isToday ? Colors.white : Colors.teal[400],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // Events Summary
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.event, color: Colors.teal[400], size: 20),
              const SizedBox(width: 8),
              Text(
                '${monthEvents.length} events this month',
                style: TextStyle(
                  color: Colors.indigo[900],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildYearView() {
    final yearEvents = getEventsForYear(selectedDate);
    final months = List.generate(12, (index) => DateTime(selectedDate.year, index + 1));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.event, color: Colors.teal[400], size: 24),
                const SizedBox(width: 12),
                Text(
                  '${yearEvents.length} events in ${selectedDate.year}',
                  style: TextStyle(
                    color: Colors.indigo[900],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = months[index];
              final monthEvents = getEventsForMonth(month);
              final today = DateTime.now();
              final isCurrentMonth = month.month == today.month &&
                  month.year == today.year;

              return GestureDetector(
                onTap: () => setState(() {
                  currentMonth = month;
                  currentView = CalendarView.month;
                }),
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrentMonth ? Colors.teal[50] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrentMonth
                        ? Border.all(color: Colors.teal[400]!, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('MMM').format(month),
                        style: TextStyle(
                          color: isCurrentMonth ? Colors.teal[700] : Colors.indigo[900],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: monthEvents.isEmpty
                              ? Colors.grey[100]
                              : Colors.teal[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${monthEvents.length}',
                          style: TextStyle(
                            color: monthEvents.isEmpty
                                ? Colors.grey[600]
                                : Colors.teal[800],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildEventCard(CalendarEvent event) {
    final startTime = event.startTime;
    final endTime = event.endTime;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: event.isAllDay ? Colors.orange[400] : Colors.teal[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[900],
                        ),
                      ),
                      if (startTime != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              event.isAllDay ? Icons.today : Icons.access_time, 
                              size: 14, 
                              color: Colors.grey[600]
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.isAllDay
                                  ? 'All day'
                                  : endTime != null
                                      ? '${DateFormat('h:mm a').format(startTime.toLocal())} - ${DateFormat('h:mm a').format(endTime.toLocal())}'
                                      : DateFormat('h:mm a').format(startTime.toLocal()),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  event.description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (event.location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.teal[400],
        elevation: 0,
        title: const Text(
          'Calendar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: Colors.white),
            onPressed: () {
              setState(() {
                selectedDate = DateTime.now();
                currentMonth = DateTime.now();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchEvents,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.teal,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading calendar events...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                buildViewSelector(),
                buildNavigationHeader(),
                Expanded(
                  child: () {
                    switch (currentView) {
                      case CalendarView.day:
                        return buildDayView();
                      case CalendarView.week:
                        return buildWeekView();
                      case CalendarView.month:
                        return buildMonthView();
                      case CalendarView.year:
                        return buildYearView();
                    }
                  }(),
                ),
              ],
            ),
    );
  }
}

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isAllDay;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    this.startTime,
    this.endTime,
    required this.isAllDay,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic dateTimeData) {
      if (dateTimeData == null) return null;
      
      try {
        if (dateTimeData is Map) {
          // Handle timed events
          if (dateTimeData['dateTime'] != null) {
            return DateTime.parse(dateTimeData['dateTime']);
          }
          // Handle all-day events
          else if (dateTimeData['date'] != null) {
            return DateTime.parse(dateTimeData['date']);
          }
        }
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
      return null;
    }

    final startData = json['start'];
    final endData = json['end'];
    final isAllDay = startData != null && startData['date'] != null;

    return CalendarEvent(
      id: json['id']?.toString() ?? '',
      title: json['summary']?.toString() ?? 'Untitled Event',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      startTime: parseDateTime(startData),
      endTime: parseDateTime(endData),
      isAllDay: isAllDay,
    );
  }

  @override
  String toString() {
    return 'CalendarEvent(id: $id, title: $title, startTime: $startTime, isAllDay: $isAllDay)';
  }
}