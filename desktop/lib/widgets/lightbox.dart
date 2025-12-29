import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/picture.dart';

class Lightbox extends StatefulWidget {
  final List<Picture> pictures;
  final int initialIndex;

  const Lightbox({
    super.key,
    required this.pictures,
    required this.initialIndex,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Picture> pictures,
    required int initialIndex,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Lightbox(
            pictures: pictures,
            initialIndex: initialIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<Lightbox> {
  late int _currentIndex;
  late PageController _pageController;
  final TransformationController _transformController = TransformationController();
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.pictures.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _goToPrevious();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _goToNext();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.space:
        setState(() => _showControls = !_showControls);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final picture = widget.pictures[_currentIndex];

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Image viewer with page view
            GestureDetector(
              onTap: () => setState(() => _showControls = !_showControls),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.pictures.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  _resetZoom();
                },
                itemBuilder: (context, index) {
                  final pic = widget.pictures[index];
                  final file = File(pic.filePath);

                  return InteractiveViewer(
                    transformationController: index == _currentIndex
                        ? _transformController
                        : null,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: FutureBuilder<bool>(
                        future: file.exists(),
                        builder: (context, snapshot) {
                          if (snapshot.data == true) {
                            return Image.file(
                              file,
                              fit: BoxFit.contain,
                            );
                          }
                          return const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 64,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // Top bar with filename and close
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                picture.fileName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${picture.width} x ${picture.height}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          color: Colors.white,
                          iconSize: 28,
                          tooltip: 'Close (Esc)',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom bar with counter and navigation
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _currentIndex > 0 ? _goToPrevious : null,
                          icon: const Icon(Icons.chevron_left),
                          color: Colors.white,
                          iconSize: 32,
                          tooltip: 'Previous',
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${_currentIndex + 1} / ${widget.pictures.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: _currentIndex < widget.pictures.length - 1
                              ? _goToNext
                              : null,
                          icon: const Icon(Icons.chevron_right),
                          color: Colors.white,
                          iconSize: 32,
                          tooltip: 'Next',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Left arrow overlay
            if (_showControls && _currentIndex > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: _goToPrevious,
                    icon: const Icon(Icons.arrow_back_ios),
                    color: Colors.white.withOpacity(0.8),
                    iconSize: 40,
                  ),
                ),
              ),

            // Right arrow overlay
            if (_showControls && _currentIndex < widget.pictures.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: _goToNext,
                    icon: const Icon(Icons.arrow_forward_ios),
                    color: Colors.white.withOpacity(0.8),
                    iconSize: 40,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
