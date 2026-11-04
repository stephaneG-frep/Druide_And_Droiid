class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.moduleId,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String body;
  final String? moduleId;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayTitle => title.trim().isEmpty ? 'Sans titre' : title.trim();
}
