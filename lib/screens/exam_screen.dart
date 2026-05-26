import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _fromCache = false;
  final Map<String, int?> _selected = {};
  final Map<String, bool> _submitted = {};

  String get _cacheKey => 'questions_cache_${widget.courseId}';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    // 1. Load cached questions
    final cached = await _loadFromCache();
    if (cached != null) {
      setState(() {
        _questions = cached;
        _loading = false;
        _fromCache = true;
      });
    }

    // 2. Fetch fresh questions
    await _fetchFreshQuestions();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _error = null;
      _loading = _questions.isEmpty;
    });
    await _fetchFreshQuestions();
  }

  // --------------- cache helpers -----------------------
  Future<List<Question>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString == null) return null;

      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((q) => Question(
        id: q['id'],
        text: q['text'],
        options: List<String>.from(q['options']),
        correctIndex: q['correctIndex'],
        explanation: q['explanation'] ?? '',
      )).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache(List<dynamic> questionsData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(questionsData));
    } catch (_) {}
  }

  // --------------- network fetch -----------------------
  Future<void> _fetchFreshQuestions() async {
    try {
      final data = await ApiService.getQuestions(widget.courseId);
      final questions = data.map((q) => Question(
        id: q['id'],
        text: q['question_text'],
        options: List<String>.from(q['options']),
        correctIndex: q['correct_index'],
        explanation: q['explanation'] ?? '',
      )).toList();

      // Save fresh data to cache (in a simple format)
      final cacheData = data.map((q) => {
        'id': q['id'],
        'text': q['question_text'],
        'options': q['options'],
        'correctIndex': q['correct_index'],
        'explanation': q['explanation'] ?? '',
      }).toList();
      await _saveToCache(cacheData);

      if (mounted) {
        setState(() {
          _questions = questions;
          _loading = false;
          _fromCache = false;
          _error = null;
        });
      }
    } on SocketException {
      _handleNetworkError('No internet connection. Pull down to retry.');
    } on http.ClientException {
      _handleNetworkError('Could not reach the server. Pull down to retry.');
    } catch (e) {
      if (_questions.isEmpty) {
        setState(() {
          _error = 'Something went wrong. Pull down to retry.';
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Could not refresh. Showing cached data.';
          _loading = false;
        });
      }
    }
  }

  void _handleNetworkError(String message) {
    if (_questions.isEmpty) {
      setState(() {
        _error = message;
        _loading = false;
      });
    } else {
      setState(() {
        _error = 'You are offline. Showing cached data.';
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
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: Column(
        children: [
          if (_error != null) _buildErrorBanner(),
          Expanded(
            child: _questions.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.quiz_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No questions available.',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _onRefresh,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
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
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    final isWarning = _fromCache || _questions.isNotEmpty;
    final color = isWarning ? Colors.orange : Colors.red;
    final icon = isWarning ? Icons.wifi_off : Icons.error_outline;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: color.shade700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}