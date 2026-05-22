import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../widgets/question_card.dart';

class ExamScreen extends StatefulWidget {
  final String courseId;
  final String? courseName;
  const ExamScreen({super.key, required this.courseId, this.courseName});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  List<Question> _questions = [];
  bool _loading = true;
  String? _error;
  final Map<String, int?> _selected = {};
  final Map<String, bool> _submitted = {};

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final data = await ApiService.getQuestions(widget.courseId);
      final questions = data.map((q) => Question(
        id: q['id'],
        text: q['question_text'],
        options: List<String>.from(q['options']),
        correctIndex: q['correct_index'],
        explanation: q['explanation'] ?? '',
      )).toList();

      setState(() {
        _questions = questions;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.courseName != null ? '${widget.courseName} Exams' : 'Exam';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    final q = _questions[index];
                    _selected.putIfAbsent(q.id, () => null);
                    _submitted.putIfAbsent(q.id, () => false);

                    return QuestionCard(
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