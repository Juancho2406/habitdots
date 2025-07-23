import 'package:flutter/material.dart';

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
  bool done;

  Habit({required this.name, this.done = false});
}

class HabitListScreen extends StatefulWidget {
  const HabitListScreen({super.key});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  final List<Habit> habits = [
    Habit(name: '🏃 Hacer ejercicio'),
    Habit(name: '🧘 Mantras'),
    Habit(name: '📚 Leer 10 min'),
    Habit(name: '💧 Tomar agua'),
  ];

  void toggleHabit(int index) {
    setState(() {
      habits[index].done = !habits[index].done;
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
                title: Text(
                  habit.name,
                  style: TextStyle(
                    fontSize: 18,
                    decoration: habit.done ? TextDecoration.lineThrough : null,
                  ),
                ),
                onTap: () {
                  setState(() {
                    habits.removeAt(index);
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}