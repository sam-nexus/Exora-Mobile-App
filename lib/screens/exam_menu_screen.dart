import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../theme.dart';

class ExamMenuScreen extends StatefulWidget {
  final String departmentId;
  final String examType; // 'model' or 'exit'
  const ExamMenuScreen({super.key, required this.departmentId, required this.examType});

  @override
  State<ExamMenuScreen> createState() => _ExamMenuScreenState();
}

class _ExamMenuScreenState extends State<ExamMenuScreen> {
  List<dynamic> _exams = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    try {
      final headers = await ApiService.headers();
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/questions/exams?department_id=${widget.departmentId}&question_type=${widget.examType}'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        setState(() {
          _exams = jsonDecode(res.body);
          _loading = false;
        });
      } else {
        setState(() => _error = 'Failed to load exams');
      }
    } catch (e) {
      setState(() => _error = 'Could not load exams. Please check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.examType == 'model' ? 'Model Exams' : 'Exit Exams';
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchExams,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _exams.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No exams available.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _exams.length,
                      itemBuilder: (_, index) {
                        final exam = _exams[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primaryGradientStart.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.assignment,
                                color: AppColors.primaryGradientStart,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              exam['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              '${exam['count']} questions',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                            onTap: () {
                              context.push('/exam/${exam['courseId']}?courseName=${Uri.encodeComponent(exam['name'])}&type=${widget.examType}');
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}