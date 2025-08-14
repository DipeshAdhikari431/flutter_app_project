class Todo {
  int? id;
  String title;
  String? note;
  bool done;
  DateTime createdAt;

  Todo({
    this.id,
    required this.title,
    this.note,
    this.done = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Todo.fromMap(Map<String, dynamic> m) => Todo(
    id: m['id'] as int?,
    title: m['title'] as String,
    note: m['note'] as String?,
    done: (m['done'] as int) == 1,
    createdAt: DateTime.parse(m['createdAt'] as String),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'note': note,
    'done': done ? 1 : 0,
    'createdAt': createdAt.toIso8601String(),
  };

  // For JSON import/export
  factory Todo.fromJson(Map<String, dynamic> j) => Todo(
    title: j['title'] as String,
    note: j['note'] as String?,
    done: (j['isDone'] ?? j['done'] ?? false) as bool,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'note': note,
    'isDone': done,
  };
}
