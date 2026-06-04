import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  File? _image;
  bool _loading = false;
  bool _loadingInfo = true;
  String? _error;
  String? _success;
  String? _uploadedImageName;
  String? _infoError;

  // Payment info from backend
  String _amount = '...';
  String _originalAmount = '';
  String? _discount;
  String _bank = '...';
  String _accountNumber = '...';
  String _accountName = '...';

  @override
  void initState() {
    super.initState();
    _fetchPaymentInfo();
  }

  Future<void> _fetchPaymentInfo() async {
    try {
      final info = await ApiService.getPaymentInfo();
      setState(() {
        _amount = info['amount'] ?? '50 ETB';
        _originalAmount = info['originalAmount'] ?? '';
        _discount = info['discount']; // can be null
        _bank = info['bank'] ?? 'Commercial Bank of Ethiopia (CBE)';
        _accountNumber = info['accountNumber'] ?? '100023456789';
        _accountName = info['accountName'] ?? 'John Dalton';
        _loadingInfo = false;
      });
    } catch (e) {
      setState(() {
        _infoError = 'Could not load payment details.';
        _loadingInfo = false;
      });
    }
  }

  void _copyAccountNumber() {
    Clipboard.setData(ClipboardData(text: _accountNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Account number copied!'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // compress slightly
        maxWidth: 1920, // limit resolution
        maxHeight: 1920,
      );
      if (picked != null) {
        setState(() {
          _image = File(picked.path);
          _uploadedImageName = picked.name;
          _error = null;
          _success = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Could not open gallery.');
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

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/payments'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('receipt', _image!.path),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        setState(() {
          _success =
              'Receipt submitted! We will verify and unlock your courses soon.';
          _image = null;
          _uploadedImageName = null;
          _loading = false;
        });
      } else {
        final body = jsonDecode(response.body);
        setState(() => _error = body['error'] ?? 'Upload failed');
        setState(() => _loading = false);
      }
    } on SocketException {
      setState(() {
        _error = 'No internet connection.';
        _loading = false;
      });
    } on http.ClientException {
      setState(() {
        _error = 'Could not reach the server.';
        _loading = false;
      });
    } on TimeoutException {
      setState(() {
        _error = 'Request timed out.';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong.';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Payment Details Card
            _loadingInfo
                ? const Center(child: CircularProgressIndicator())
                : _infoError != null
                ? Center(
                    child: Text(
                      _infoError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with discount badge
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryGradientStart
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.payment,
                                color: AppColors.primaryGradientStart,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Payment Details',
                              style: AppTextStyles.heading2.copyWith(
                                color: onSurfaceColor,
                                fontSize: 18,
                              ),
                            ),
                            const Spacer(),
                            if (_discount != null && _discount!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF6584),
                                      Color(0xFFFF3D5A),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF6584,
                                      ).withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_offer,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_discount OFF',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Amount row with original price strikethrough
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _amount,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGradientStart,
                              ),
                            ),
                            if (_originalAmount.isNotEmpty &&
                                _discount != null) ...[
                              const SizedBox(width: 10),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  _originalAmount,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: onSurfaceColor.withOpacity(0.4),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        _infoRow('Bank', _bank, onSurfaceColor),
                        const SizedBox(height: 12),
                        _infoRow('Account Name', _accountName, onSurfaceColor),
                        const SizedBox(height: 12),

                        // Account number with copy
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 130,
                              child: Text(
                                'Account No.',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: onSurfaceColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _accountNumber,
                                style: TextStyle(
                                  color: onSurfaceColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _copyAccountNumber,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGradientStart
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.copy,
                                      size: 16,
                                      color: AppColors.primaryGradientStart,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Copy',
                                      style: TextStyle(
                                        color: AppColors.primaryGradientStart,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 24),

            // Upload Section
            Text(
              'Upload Payment Screenshot',
              style: AppTextStyles.heading2.copyWith(
                color: onSurfaceColor,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
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
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                padding: EdgeInsets.zero,
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
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 56,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to select a screenshot',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'JPG, PNG or PDF',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_uploadedImageName != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Selected: $_uploadedImageName',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_error != null) _buildMessageBanner(_error!, isError: true),
            if (_success != null)
              _buildMessageBanner(_success!, isError: false),

            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1A3E), Color(0xFF0D0D2B)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit Payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBanner(String message, {required bool isError}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.red.shade700 : Colors.green.shade700,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? Colors.red.shade700 : Colors.green.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
