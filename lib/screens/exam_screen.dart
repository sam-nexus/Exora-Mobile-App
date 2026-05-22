import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models.dart';
import '../widgets/question_card.dart';   // <-- must be present

final List<Question> _mockQuestions = const [
  Question(
    id: '1',
    text: 'What is the time complexity of binary search?',
    options: ['O(n)', 'O(log n)', 'O(n^2)', 'O(1)'],
    correctIndex: 1,
    explanation: 'Binary search halves the search space each step.',
  ),
  Question(
    id: '2',
    text: 'Which data structure uses LIFO?',
    options: ['Queue', 'Stack', 'Array', 'Linked List'],
    correctIndex: 1,
    explanation: 'Stack stands for Last-In-First-Out.',
  ),
  Question(
    id: '3',
    text: 'What is the capital of France?',
    options: ['Berlin', 'Madrid', 'Paris', 'Rome'],
    correctIndex: 2,
    explanation: 'Paris is the capital of France.',
  ),
];

class ExamScreen extends StatefulWidget {
  final String courseId;
  final String? courseName;
  const ExamScreen({super.key, required this.courseId, this.courseName});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final Map<String, int?> _selected = {};
  final Map<String, bool> _submitted = {};

  @override
  Widget build(BuildContext context) {
    final title = widget.courseName != null
        ? '${widget.courseName} Exams'
        : 'Exam';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _mockQuestions.length,
        itemBuilder: (context, index) {
          final q = _mockQuestions[index];
          _selected.putIfAbsent(q.id, () => null);
          _submitted.putIfAbsent(q.id, () => false);

          return QuestionCard(    // <-- now finds the class
            question: q,
            questionNumber: index + 1,
            selectedIndex: _selected[q.id],
            isSubmitted: _submitted[q.id]!,
            onOptionSelected: (optionIndex) {
              if (!_submitted[q.id]!) {
                setState(() => _selected[q.id] = optionIndex);
              }
            },
            onSubmit: () {
              if (_selected[q.id] != null && !_submitted[q.id]!) {
                setState(() => _submitted[q.id] = true);
              }
            },
          );
        },
      ),
    );
  }
}