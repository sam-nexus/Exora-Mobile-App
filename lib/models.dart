class Department {
  final String id;
  final String name;
  final String icon; // emoji
  const Department({required this.id, required this.name, required this.icon});
}

class Course {
  final String id;
  final String departmentId;
  final String name;
  final bool isLocked;
  const Course({
    required this.id,
    required this.departmentId,
    required this.name,
    required this.isLocked,
  });
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctIndex; // 0‑based
  final String explanation;
  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}