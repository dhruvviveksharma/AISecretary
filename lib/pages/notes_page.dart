import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Note> notes = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final savedNotes = prefs.getStringList('notes') ?? [];

    setState(() {
      notes = savedNotes
          .map((noteString) => Note.fromJson(jsonDecode(noteString)))
          .toList();
      // Sort by updated date (most recent first)
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      isLoading = false;
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'notes',
      notes.map((note) => jsonEncode(note.toJson())).toList(),
    );
  }

  void _addNewNote() {
    final now = DateTime.now();
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Note',
      content: '',
      createdAt: now,
      updatedAt: now,
    );

    setState(() {
      notes.insert(0, newNote);
    });
    _saveNotes();
    _showNoteEditor(newNote);
  }

  void _showNoteEditor(Note note) {
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Note',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo[900],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.grey[700]),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Title Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          labelStyle: TextStyle(color: Colors.indigo[700]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.title, color: Colors.purple[400]),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo[900],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Content Field
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: contentController,
                          decoration: InputDecoration(
                            labelText: 'Write your note here...',
                            labelStyle: TextStyle(color: Colors.indigo[700]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            alignLabelWithHint: true,
                            contentPadding: EdgeInsets.all(16),
                          ),
                          maxLines: null,
                          expands: false,
                          keyboardType: TextInputType.multiline,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Save Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          final updatedNote = note.copyWith(
                            title: titleController.text.trim().isEmpty 
                                ? 'Untitled' 
                                : titleController.text.trim(),
                            content: contentController.text,
                            updatedAt: DateTime.now(),
                          );
                          
                          setState(() {
                            final index = notes.indexWhere((n) => n.id == note.id);
                            if (index != -1) {
                              notes[index] = updatedNote;
                              // Resort by updated date
                              notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                            }
                          });
                          
                          _saveNotes();
                          Navigator.pop(context);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Note saved successfully!'),
                              backgroundColor: Colors.teal,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[400],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save Note',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteNote(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Delete Note',
          style: TextStyle(
            color: Colors.indigo[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this note? This action cannot be undone.',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                notes.removeWhere((note) => note.id == id);
              });
              _saveNotes();
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Note deleted successfully!'),
                  backgroundColor: Colors.red[400],
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<Note> get _filteredNotes {
    if (_searchQuery.isEmpty) return notes;
    return notes.where((note) {
      return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.purple[400],
        elevation: 0,
        title: Text(
          'Notes',
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
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NotesSearchDelegate(notes, _showNoteEditor),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadNotes,
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.teal,
                strokeWidth: 3,
              ),
            )
          : notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.note_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'No notes found',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.indigo[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the + button to create your first note!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotes,
                  color: Colors.teal,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredNotes.length,
                    physics: AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final note = _filteredNotes[index];
                      final isRecent = DateTime.now().difference(note.updatedAt).inDays < 1;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.white,
                        child: InkWell(
                          onTap: () => _showNoteEditor(note),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        note.title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo[900],
                                        ),
                                      ),
                                    ),
                                    if (isRecent)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.teal[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Recent',
                                          style: TextStyle(
                                            color: Colors.teal[800],
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red[400],
                                        size: 20,
                                      ),
                                      onPressed: () => _deleteNote(note.id),
                                      constraints: BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                                
                                if (note.content.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    note.content.length > 150
                                        ? '${note.content.substring(0, 150)}...'
                                        : note.content,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                                
                                const SizedBox(height: 12),
                                
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Updated ${DateFormat('MMM d, y - h:mm a').format(note.updatedAt)}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Spacer(),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo[50],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${note.content.split(' ').length} words',
                                        style: TextStyle(
                                          color: Colors.indigo[700],
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _addNewNote,
          backgroundColor: Colors.teal[400],
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class NotesSearchDelegate extends SearchDelegate {
  final List<Note> notes;
  final Function(Note) onNoteSelected;

  NotesSearchDelegate(this.notes, this.onNoteSelected);

  @override
  String get searchFieldLabel => 'Search notes...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.teal[400],
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final filteredNotes = notes.where((note) {
      return note.title.toLowerCase().contains(query.toLowerCase()) ||
          note.content.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (filteredNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No notes found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.grey[300],
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredNotes.length,
        itemBuilder: (context, index) {
          final note = filteredNotes[index];
          return Card(
            margin: EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              title: Text(
                note.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[900],
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note.content.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      note.content.length > 100
                          ? '${note.content.substring(0, 100)}...'
                          : note.content,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                  SizedBox(height: 8),
                  Text(
                    'Updated: ${DateFormat('MMM d, y').format(note.updatedAt)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              onTap: () {
                close(context, null);
                onNoteSelected(note);
              },
            ),
          );
        },
      ),
    );
  }
}

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Note.fromJson(Map<String, dynamic> data) {
    return Note(
      id: data['id'],
      title: data['title'],
      content: data['content'],
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: DateTime.parse(data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}