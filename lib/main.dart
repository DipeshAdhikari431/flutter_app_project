import 'package:flutter/material.dart';

void main() {
  runApp(const TodoApp());
}

class Todo {
  String title;
  String? note;
  bool done;
  Todo({required this.title, this.note, this.done = false});
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple ToDo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const TodoHomePage(),
    );
  }
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final List<Todo> _todos = [
    Todo(title: 'Open the todolist app', note: 'In the morning'),
    Todo(title: 'Toggle a task', note: 'Go to bathroom'),
    Todo(title: 'Project Alex', note: 'see the JIRA task'),
  ];

  @override
  Widget build(BuildContext context) {
    final completed = _todos.where((t) => t.done).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple ToDo'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '$completed / ${_todos.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Clear completed',
            onPressed: () {
              setState(() => _todos.removeWhere((t) => t.done));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cleared completed tasks')),
              );
            },
            icon: const Icon(Icons.cleaning_services),
          ),
        ],
      ),
      body: _todos.isEmpty
          ? const _EmptyState()
          : ListView.separated(
        itemCount: _todos.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, i) {
          final t = _todos[i];
          return Dismissible(
            key: ValueKey('${t.title}-$i'),
            background: _swipeBg(alignment: Alignment.centerLeft),
            secondaryBackground: _swipeBg(alignment: Alignment.centerRight),
            onDismissed: (_) {
              setState(() => _todos.removeAt(i));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "${t.title}"')),
              );
            },
            child: ListTile(
              leading: Checkbox(
                value: t.done,
                onChanged: (_) => setState(() => t.done = !t.done),
              ),
              title: Text(
                t.title,
                style: TextStyle(
                  decoration: t.done ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: (t.note?.isNotEmpty ?? false) ? Text(t.note!) : null,
              onTap: () => _showAddEditDialog(existingIndex: i),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _swipeBg({required Alignment alignment}) {
    return Container(
      color: Colors.red,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Future<void> _showAddEditDialog({int? existingIndex}) async {
    final isEdit = existingIndex != null;
    final titleCtrl = TextEditingController(
      text: isEdit ? _todos[existingIndex].title : '',
    );
    final noteCtrl = TextEditingController(
      text: isEdit ? (_todos[existingIndex].note ?? '') : '',
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Edit Task' : 'Add Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Buy milk',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Details, due date, etc.',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          if (isEdit)
            TextButton(
              onPressed: () {
                setState(() => _todos.removeAt(existingIndex));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task deleted')),
                );
              },
              child: const Text('Delete'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final note = noteCtrl.text.trim();
              if (title.isEmpty) return;
              setState(() {
                if (isEdit) {
                  final t = _todos[existingIndex!];
                  t.title = title;
                  t.note = note.isEmpty ? null : note;
                } else {
                  _todos.insert(0, Todo(title: title, note: note.isEmpty ? null : note));
                }
              });
              Navigator.pop(context);
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No tasks yet.\nTap + to add your first one!',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
