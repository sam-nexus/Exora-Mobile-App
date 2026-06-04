import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../services/api_service.dart';
import '../theme.dart';

class MaterialsScreen extends StatefulWidget {
  final String courseId;
  final String? courseName;
  const MaterialsScreen({super.key, required this.courseId, this.courseName});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  List<dynamic> _materials = [];
  bool _loading = true;
  String? _error;
  Map<String, String> _downloadedFiles = {};
  final Map<String, bool> _downloading = {};

  @override
  void initState() {
    super.initState();
    _loadMaterials();
    _loadDownloadedFiles();
  }

  Future<void> _loadDownloadedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'downloaded_materials_${widget.courseId}';
    final data = prefs.getString(key);
    if (data != null) {
      setState(() {
        _downloadedFiles = Map<String, String>.from(jsonDecode(data));
      });
    }
  }

  Future<void> _saveDownloadedFile(String title, String path) async {
    _downloadedFiles[title] = path;
    final prefs = await SharedPreferences.getInstance();
    final key = 'downloaded_materials_${widget.courseId}';
    await prefs.setString(key, jsonEncode(_downloadedFiles));
  }

  Future<void> _loadMaterials() async {
    try {
      final authHeaders = await ApiService.headers();
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/courses/${widget.courseId}/materials'),
        headers: authHeaders,
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        setState(() {
          _materials = jsonDecode(res.body);
          _loading = false;
        });
      } else {
        setState(() => _error = 'Failed to load materials');
      }
    } catch (e) {
      setState(() => _error = 'Could not load materials.');
    }
  }

  Future<void> _downloadFile(String title, String url) async {
    setState(() {
      _downloading[title] = true;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${title.replaceAll(' ', '_')}.pdf';

      await Dio().download(url, filePath);
      await _saveDownloadedFile(title, filePath);

      setState(() {
        _downloading[title] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title downloaded successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _downloading[title] = false;
        _error = 'Download failed for $title.';
      });
    }
  }

  void _openPdf(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('PDF Viewer'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: PDFView(filePath: path),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.courseName != null ? '${widget.courseName} Materials' : 'Course Materials';
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
                        onPressed: _loadMaterials,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _materials.isEmpty
                  ? const Center(child: Text('No materials available.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _materials.length,
                      itemBuilder: (_, index) {
                        final mat = _materials[index];
                        final localPath = _downloadedFiles[mat['title']];
                        final isDownloaded = localPath != null;
                        final isDownloading = _downloading[mat['title']] ?? false;

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
                                color: isDownloaded ? Colors.green.shade50 : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isDownloaded ? Icons.picture_as_pdf : Icons.picture_as_pdf_outlined,
                                color: isDownloaded ? Colors.green : Colors.red,
                                size: 24,
                              ),
                            ),
                            title: Text(mat['title'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                            trailing: isDownloading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : isDownloaded
                                    ? ElevatedButton.icon(
                                        icon: const Icon(Icons.visibility, size: 18),
                                        label: const Text('View'),
                                        onPressed: () => _openPdf(localPath),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        ),
                                      )
                                    : ElevatedButton.icon(
                                        icon: const Icon(Icons.download, size: 18),
                                        label: const Text('Download'),
                                        onPressed: () => _downloadFile(mat['title'], mat['file_url']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryGradientStart,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        ),
                                      ),
                          ),
                        );
                      },
                    ),
    );
  }
}