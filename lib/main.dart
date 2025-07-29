import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:table_calendar/table_calendar.dart' show CalendarFormat;

void main() {
  runApp(const HabitDotsApp());
}

class HabitDotsApp extends StatelessWidget {
  const HabitDotsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'habitdots',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HabitListScreen(),
    );
  }
}

class Habit {
  final String name;
  final String? description;
  bool done;
  List<String>? log;

  Habit({required this.name, this.description, this.done = false, this.log});

  int get streak {
    if (log == null || log!.isEmpty) return 0;
    final dates = log!
        .map((e) => DateTime.parse(e))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int count = 0;
    DateTime current = DateTime.now();

    for (final date in dates) {
      if (_isSameDay(date, current)) {
        count++;
        current = current.subtract(const Duration(days: 1));
      } else if (date.isBefore(current)) {
        break;
      }
    }
    return count;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class HabitListScreen extends StatefulWidget {
  const HabitListScreen({super.key});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  // final List<Habit> habits = [
  //   Habit(name: '🏃 Hacer ejercicio'),
  //   Habit(name: '🧘 Mantras'),
  //   Habit(name: '📚 Leer 10 min'),
  //   Habit(name: '💧 Tomar agua'),
  // ];
  List<Habit> habits = [];

  Future<List<Habit>> fetchHabits() async {
    const url = 'https://2eh0hty21h.execute-api.us-east-1.amazonaws.com/v1/habits';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) {
        final today = DateTime.now().toIso8601String().split('T').first;
        final logList = item['log'] != null ? List<String>.from(item['log'].map((e) => e.toString())) : null;
        final doneToday = logList?.contains(today) ?? false;
        return Habit(
          name: item['name'],
          description: item['description'],
          log: logList,
          done: doneToday,
        );
      }).toList();
    } else {
      throw Exception('Error al cargar hábitos');
    }
  }

  Future<bool> updateHabit({required String name, required String description, required List<String> log}) async {
    final url = 'https://2eh0hty21h.execute-api.us-east-1.amazonaws.com/v1/habits/juan/$name';
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "habit_id": "juan#$name",
        "user_id": "juan",
        "name": name,
        "description": description,
        "log": log,
      }),
    );

    return response.statusCode == 200 || response.statusCode == 204;
  }

  @override
  void initState() {
    super.initState();
    fetchHabits().then((loadedHabits) {
      setState(() {
        habits = loadedHabits;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('habitdots 🟢'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: habits.length,
        itemBuilder: (context, index) {
          final habit = habits[index];
          return Dismissible(
            key: Key(habit.name),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              setState(() {
                habits.removeAt(index);
              });
            },
            background: Container(
              color: Colors.redAccent,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Checkbox(
                  value: habit.done,
                  onChanged: (checked) async {
                    final today = DateTime.now().toIso8601String().split('T').first;
                    List<String> updatedLog = [...habit.log?.map((e) => e.toString()) ?? []];
                    if (checked == true) {
                      updatedLog.add(today);
                    } else {
                      updatedLog.removeWhere((date) => date == today);
                    }

                    final updated = await updateHabit(
                      name: habit.name,
                      description: habit.description ?? '',
                      log: updatedLog,
                    );

                    if (updated) {
                      setState(() {
                        habit.done = checked ?? false;
                        habit.log = updatedLog;
                      });
                    }
                  },
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 18,
                        decoration: habit.done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      '${habit.streak} 🔥',
                      style: const TextStyle(fontSize: 16, color: Colors.orange),
                    ),
                  ],
                ),
                onTap: () async {
                  final deleted = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HabitDetailScreen(habit: habit),
                    ),
                  );
                  if (deleted == true) {
                    setState(() {
                      habits.removeAt(index);
                    });
                  }
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newHabit = await Navigator.push<Habit>(
            context,
            MaterialPageRoute(builder: (context) => const CreateHabitScreen()),
          );
          if (newHabit != null) {
            setState(() {
              habits.add(newHabit);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
class HabitDetailScreen extends StatelessWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    Future<void> deleteHabit(String name) async {
      final url = 'https://2eh0hty21h.execute-api.us-east-1.amazonaws.com/v1/habits/juan/$name';
      final response = await http.delete(Uri.parse(url));
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (context.mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar hábito')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              habit.description ?? 'Sin descripción',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Historial del hábito',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: DateTime.now(),
                calendarFormat: CalendarFormat.month,
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                selectedDayPredicate: (day) {
                  final formatted = day.toIso8601String().split('T').first;
                  return habit.log?.contains(formatted) ?? false;
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekendStyle: TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: () => deleteHabit(habit.name),
        child: const Icon(Icons.delete),
      ),
    );
  }
}
class CreateHabitScreen extends StatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  Future<Habit?> createHabit(String name, String description) async {
    const url = 'https://2eh0hty21h.execute-api.us-east-1.amazonaws.com/v1/habits';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "habit_id": "juan#$name",
        "user_id": "juan",
        "name": name,
        "description": description,
        "log": [],
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Habit(name: name, description: description);
    } else {
      throw Exception('Error al crear hábito');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo hábito')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese un nombre' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final habit = await createHabit(
                        _nameController.text,
                        _descController.text,
                      );
                      if (context.mounted) Navigator.pop(context, habit);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error al crear hábito')),
                      );
                    }
                  }
                },
                child: const Text('Crear hábito'),
              )
            ],
          ),
        ),
      ),
    );
  }
}