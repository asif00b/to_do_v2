import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting date & time
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON encoding/decoding

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-Do List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light, // Light theme
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark, // Dark theme
      ),
      home: WelcomeScreen(),
    );
  }
}

// Welcome Screen
class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Navigate to the To-Do List screen after 2.5 seconds
    Future.delayed(Duration(milliseconds: 2500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TodoScreen()),
      );
    });

    return Scaffold(
      backgroundColor: Colors.blue, // Customize background color
      body: Center(
        child: Text(
          'Welcome',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class TodoScreen extends StatefulWidget {
  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Map<String, dynamic>> tasks = []; // Stores task, date, and wholeDay option
  TextEditingController taskController = TextEditingController();
  bool isWholeDay = false;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String searchQuery = ""; // For search functionality

  // Key for storing tasks in SharedPreferences
  final String _tasksKey = "tasks";

  @override
  void initState() {
    super.initState();
    _loadTasks(); // Load tasks when the app starts
  }

  // Function to load tasks from SharedPreferences
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString(_tasksKey);

    if (tasksString != null) {
      setState(() {
        tasks = (json.decode(tasksString) as List).map((task) {
          return {
            'title': task['title'],
            'dateTime': task['dateTime'],
            'isWholeDay': task['isWholeDay'],
          };
        }).toList();
      });
    }
  }

  // Function to save tasks to SharedPreferences
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String tasksString = json.encode(tasks);
    await prefs.setString(_tasksKey, tasksString);
  }

  // Function to add or update a task
  void addOrUpdateTask({bool isEditing = false, int? index}) {
    if (taskController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a task title")),
      );
      return;
    }
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a date")),
      );
      return;
    }

    DateTime taskDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      isWholeDay ? 0 : selectedTime!.hour,
      isWholeDay ? 0 : selectedTime!.minute,
    );

    setState(() {
      if (isEditing && index != null) {
        tasks[index] = {
          'title': taskController.text,
          'dateTime': taskDateTime.toIso8601String(),
          'isWholeDay': isWholeDay,
        };
      } else {
        tasks.add({
          'title': taskController.text,
          'dateTime': taskDateTime.toIso8601String(),
          'isWholeDay': isWholeDay,
        });
      }
      taskController.clear();
      isWholeDay = false;
      selectedDate = null;
      selectedTime = null;
    });
    _saveTasks();
    Navigator.pop(context);
  }

  // Function to select date
  Future<void> pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });

      // Show dialog to choose between Whole Day or Select Time
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Choose Option"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isWholeDay = true;
                      selectedTime = null;
                    });
                    Navigator.pop(context);
                  },
                  child: Text("Whole Day"),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      isWholeDay = false;
                    });
                    Navigator.pop(context);
                    await pickTime();
                  },
                  child: Text("Select Time"),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  // Function to select time
  Future<void> pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  // Function to delete a task
  void deleteTask(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Task"),
          content: Text("Are you sure you want to delete this task?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  tasks.removeAt(index);
                });
                _saveTasks();
                Navigator.pop(context);
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Function to show the bottom sheet for adding/editing a task
  void _showAddTaskBottomSheet({bool isEditing = false, int? index}) {
    if (isEditing && index != null) {
      final task = tasks[index];
      taskController.text = task['title'];
      selectedDate = DateTime.parse(task['dateTime']);
      isWholeDay = task['isWholeDay'];
      if (!isWholeDay) {
        selectedTime = TimeOfDay.fromDateTime(DateTime.parse(task['dateTime']));
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskController,
                  decoration: InputDecoration(
                    hintText: 'Enter a task',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: pickDate,
                  child: Text(selectedDate == null
                      ? "Pick Date"
                      : isWholeDay
                      ? "${DateFormat('yyyy-MM-dd').format(selectedDate!)} (Whole Day)"
                      : "${DateFormat('yyyy-MM-dd').format(selectedDate!)} ${selectedTime?.format(context) ?? ''}"),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => addOrUpdateTask(isEditing: isEditing, index: index),
                  child: Text(isEditing ? "Update Task" : "Add Task"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Function to sort tasks by date and time
  void sortTasks() {
    setState(() {
      tasks.sort((a, b) => DateTime.parse(a['dateTime']).compareTo(DateTime.parse(b['dateTime'])));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sort tasks whenever the list is rebuilt
    sortTasks();

    // Filter tasks based on search query
    final filteredTasks = tasks.where((task) =>
        task['title'].toLowerCase().contains(searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: TaskSearchDelegate(tasks),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                final DateTime taskDateTime = DateTime.parse(task['dateTime']);
                final formattedDateTime = task['isWholeDay']
                    ? DateFormat('yyyy-MM-dd').format(taskDateTime) + " (Whole Day)"
                    : DateFormat('yyyy-MM-dd hh:mm a').format(taskDateTime);

                return Dismissible(
                  key: Key(task['dateTime']),
                  onDismissed: (direction) {
                    deleteTask(tasks.indexOf(task));
                  },
                  background: Container(color: Colors.red),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text("${index + 1}"),
                    ),
                    title: Text(task['title']),
                    subtitle: Text("Date: $formattedDateTime"),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _showAddTaskBottomSheet(isEditing: true, index: tasks.indexOf(task)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskBottomSheet(),
        child: Icon(Icons.add),
      ),
    );
  }
}

// Search Delegate for Task Search
class TaskSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> tasks;

  TaskSearchDelegate(this.tasks);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null!);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final filteredTasks = tasks.where((task) =>
        task['title'].toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return ListTile(
          title: Text(task['title']),
          subtitle: Text("Date: ${task['dateTime']}"),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredTasks = tasks.where((task) =>
        task['title'].toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return ListTile(
          title: Text(task['title']),
          subtitle: Text("Date: ${task['dateTime']}"),
        );
      },
    );
  }
}