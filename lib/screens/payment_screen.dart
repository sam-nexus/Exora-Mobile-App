import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  File? _image;
  bool _loading = false;
  String? _error;
  String? _success;
  String? _uploadedImageName;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _image = File(picked.path);
          _uploadedImageName = picked.name;
          _error = null;
          _success = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Could not open gallery: ${e.toString()}');
    }
  }

  Future<void> _submit() async {
    if (_image == null) {
      setState(() => _error = 'Please select a screenshot of your payment.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) {
        setState(() {
          _error = 'You are not logged in. Please log in again.';
          _loading = false;
        });
        return;
      }

      print('🔍 Uploading receipt to server...');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://exora-app.onrender.com/api/payments'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('receipt', _image!.path));

      print('📤 Sending file: ${_image!.path}');
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      print('📬 Response status: ${response.statusCode}');
      print('📬 Response body: ${response.body}');

      if (response.statusCode == 201) {
        setState(() {
          _success = 'Receipt submitted! We will verify and unlock your courses soon.';
          _image = null;
          _uploadedImageName = null;
          _loading = false;
        });
      } else {
        final body = jsonDecode(response.body);
        final errorMsg = body['error'] ?? 'Upload failed';
        setState(() => _error = errorMsg);
        setState(() => _loading = false);
      }
    } on SocketException {
      setState(() {
        _error = 'No internet connection. Please check your network.';
        _loading = false;
      });
    } on http.ClientException {
      setState(() {
        _error = 'Could not reach the server. Please try again later.';
        _loading = false;
      });
    } on TimeoutException {
      setState(() {
        _error = 'The request timed out. Please try again.';
        _loading = false;
      });
    } catch (e) {
      print('❌ Payment error: $e');
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = theme.colorScheme.surface;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final subtitleColor = onSurfaceColor.withOpacity(0.6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Details',
                      style: AppTextStyles.heading2.copyWith(color: onSurfaceColor)),
                  const SizedBox(height: 16),
                  _infoRow('Amount', '50 ETB', subtitleColor, onSurfaceColor),
                  _infoRow('Bank', 'Commercial Bank of Ethiopia (CBE)', subtitleColor, onSurfaceColor),
                  _infoRow('Account Number', '100023456789', subtitleColor, onSurfaceColor),
                  _infoRow('Account Name', 'John Dalton', subtitleColor, onSurfaceColor),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Upload Screenshot',
                style: AppTextStyles.heading2.copyWith(color: onSurfaceColor)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _error != null && _image == null
                        ? Colors.red.shade300
                        : isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                    width: _error != null && _image == null ? 1.5 : 1,
                  ),
                ),
                child: _image != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_image!, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                onPressed: () => setState(() {
                                  _image = null;
                                  _uploadedImageName = null;
                                  _error = null;
                                }),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              size: 48, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                          const SizedBox(height: 8),
                          Text('Tap to select a screenshot',
                              style: TextStyle(color: subtitleColor)),
                        ],
                      ),
              ),
            ),
            if (_uploadedImageName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Selected: $_uploadedImageName',
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            if (_success != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _success!,
                        style: TextStyle(color: Colors.green.shade700, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Submit Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: labelColor)),
          ),
          Expanded(child: Text(value, style: TextStyle(color: valueColor))),
        ],
      ),
    );
  }
}