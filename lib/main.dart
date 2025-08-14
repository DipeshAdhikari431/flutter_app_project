import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/todo.dart';
import 'providers/todo_provider.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TodoProvider()..init(),
      child: MaterialApp(
        title: 'Simple ToDo (SQLite + JSON)',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
        ),
        home: const TodoHomePage(),
      ),
    );
  }
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();
    final completed = provider.todos.where((t) => t.done).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple ToDo'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '$completed / ${provider.todos.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Export JSON',
            onPressed: () async {
              final path = await context.read<TodoProvider>().exportToDocuments();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Exported to: $path')),
              );
            },
            icon: const Icon(Icons.download),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'import_asset') {
                await context.read<TodoProvider>().importFromAsset('assets/todos_seed.json');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Imported seed from assets')),
                );
              } else if (v == 'import_docs') {
                await _promptImportFromDocs(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'import_asset', child: Text('Import seed (assets)')),
              PopupMenuItem(value: 'import_docs', child: Text('Import from documents...')),
            ],
          ),
        ],
      ),
      body: provider.todos.isEmpty
          ? const _EmptyState()
          : ListView.separated(
        itemCount: provider.todos.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, i) {
          final t = provider.todos[i];
          return Dismissible(
            key: ValueKey(t.id),
            background: _swipeBg(Alignment.centerLeft),
            secondaryBackground: _swipeBg(Alignment.centerRight),
            onDismissed: (_) {
              context.read<TodoProvider>().remove(t);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "${t.title}"')),
              );
            },
            child: ListTile(
              leading: Checkbox(
                value: t.done,
                onChanged: (_) => context.read<TodoProvider>().toggle(t),
              ),
              title: Text(
                t.title,
                style: TextStyle(
                  decoration: t.done ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: (t.note?.isNotEmpty ?? false) ? Text(t.note!) : null,
              onTap: () => _showAddEditDialog(existing: t),
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

  Widget _swipeBg(Alignment a) => Container(
    color: Colors.red,
    alignment: a,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: const Icon(Icons.delete, color: Colors.white),
  );

  Future<void> _showAddEditDialog({Todo? existing}) async {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Edit Task' : 'Add Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g., Buy milk'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          if (isEdit)
            TextButton(
              onPressed: () {
                context.read<TodoProvider>().remove(existing!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task deleted')),
                );
              },
              child: const Text('Delete'),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final note = noteCtrl.text.trim();
              if (title.isEmpty) return;

              final prov = context.read<TodoProvider>();
              if (isEdit) {
                await prov.update(existing!, title: title, note: note);
              } else {
                await prov.add(Todo(title: title, note: note.isEmpty ? null : note));
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _promptImportFromDocs(BuildContext context) async {
    final ctrl = TextEditingController(text: 'todos_export.json');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import from documents'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'File name in app documents',
            helperText: 'Default: todos_export.json',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await context.read<TodoProvider>().importFromDocuments(ctrl.text.trim(), merge: true);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      'No tasks yet.\nTap + to add your first one!',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium,
    ),
  );
}
