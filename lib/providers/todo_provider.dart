import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../data/database_helper.dart';
import '../models/todo.dart';

class TodoProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final List<Todo> _todos = [];

  List<Todo> get todos => List.unmodifiable(_todos);

  Future<void> init() async {
    await _loadFromDb();
    if (_todos.isEmpty) {
      await importFromAsset('assets/todos_seed.json');
    }
  }

  Future<void> _loadFromDb() async {
    final rows = await _db.queryAll();
    _todos
      ..clear()
      ..addAll(rows.map(Todo.fromMap));
    notifyListeners();
  }

  Future<void> add(Todo t) async {
    final id = await _db.insert(t.toMap());
    t.id = id;
    _todos.insert(0, t);
    notifyListeners();
  }

  Future<void> toggle(Todo t) async {
    t.done = !t.done;
    await _db.update(t.id!, t.toMap());
    notifyListeners();
  }

  Future<void> update(Todo t, {required String title, String? note}) async {
    t.title = title;
    t.note = (note?.trim().isEmpty ?? true) ? null : note!.trim();
    await _db.update(t.id!, t.toMap());
    notifyListeners();
  }

  Future<void> remove(Todo t) async {
    await _db.delete(t.id!);
    _todos.removeWhere((x) => x.id == t.id);
    notifyListeners();
  }

  // ---------- JSON helpers ----------
  Future<void> importFromAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    for (final m in list) {
      await add(Todo.fromJson(m));
    }
  }

  Future<String> exportToDocuments({String fileName = 'todos_export.json'}) async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/$fileName');
    final data = _todos.map((t) => t.toJson()).toList();
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return f.path;
  }

  Future<void> importFromDocuments(String fileName, {bool merge = true}) async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/$fileName');
    if (!await f.exists()) return;

    final raw = await f.readAsString();
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    if (!merge) {
      for (final t in List<Todo>.from(_todos)) {
        await remove(t);
      }
    }
    for (final m in list) {
      await add(Todo.fromJson(m));
    }
  }
}
