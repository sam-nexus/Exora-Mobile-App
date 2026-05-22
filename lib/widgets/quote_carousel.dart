import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';

class QuoteCarousel extends StatefulWidget {
  final List<String> quotes;
  final Duration autoSlideInterval;
  const QuoteCarousel({
    super.key,
    required this.quotes,
    this.autoSlideInterval = const Duration(seconds: 5),
  });

  @override
  State<QuoteCarousel> createState() => _QuoteCarouselState();
}

class _QuoteCarouselState extends State<QuoteCarousel> {
  late PageController _controller;
  int _currentPage = 0;
  Timer? _timer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.85);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    if (widget.quotes.length < 2) return;

    _timer = Timer.periodic(widget.autoSlideInterval, (_) {
      if (!_isUserInteracting && _controller.hasClients) {
        final nextPage = (_currentPage + 1) % widget.quotes.length;
        _controller.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _startAutoSlide();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onPanDown: (_) {
        setState(() => _isUserInteracting = true);
      },
      onPanCancel: () {
        setState(() => _isUserInteracting = false);
        _startAutoSlide();
      },
      onPanEnd: (_) {
        setState(() => _isUserInteracting = false);
        _startAutoSlide();
      },
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.quotes.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2C2C54), const Color(0xFF1B1B3A)]
                    : [const Color(0xFF2C2C54), const Color(0xFF1B1B3A)], // always dark cards
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                widget.quotes[index],
                style: AppTextStyles.heading2.copyWith(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}