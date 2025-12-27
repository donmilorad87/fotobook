import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/file_service.dart';
import '../state/app_state.dart';

const _supportedImageExtensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'};

class ImportGalleryScreen extends StatefulWidget {
  const ImportGalleryScreen({super.key});

  @override
  State<ImportGalleryScreen> createState() => _ImportGalleryScreenState();
}

class _ImportGalleryScreenState extends State<ImportGalleryScreen> {
  final _nameController = TextEditingController();
  String? _selectedFolder;
  List<File> _images = [];
  bool _isScanning = false;
  bool _isImporting = false;
  int _importProgress = 0;
  int _importTotal = 0;
  bool _isDragging = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectFolder() async {
    final fileService = context.read<FileService>();
    final folder = await fileService.pickFolder();

    if (folder != null) {
      setState(() {
        _selectedFolder = folder;
        _isScanning = true;
        _images = [];
      });

      // Auto-fill gallery name from folder name
      final folderName = folder.split(Platform.pathSeparator).last;
      _nameController.text = folderName;

      // Scan for images
      final images = await fileService.scanFolderForImages(folder);

      setState(() {
        _images = images;
        _isScanning = false;
      });
    }
  }

  Future<void> _handleDroppedFiles(List<DropDoneDetails> details) async {
    if (_isImporting) return;

    final droppedFiles = details.expand((d) => d.files).toList();
    if (droppedFiles.isEmpty) return;

    setState(() => _isScanning = true);

    final newImages = <File>[];

    for (final xFile in droppedFiles) {
      final path = xFile.path;
      final file = File(path);

      if (await FileSystemEntity.isDirectory(path)) {
        // If a folder is dropped, scan it for images
        final fileService = context.read<FileService>();
        final folderImages = await fileService.scanFolderForImages(path);
        newImages.addAll(folderImages);

        // Use folder name if no name set yet
        if (_nameController.text.isEmpty) {
          _nameController.text = path.split(Platform.pathSeparator).last;
        }
        _selectedFolder ??= path;
      } else if (await file.exists()) {
        // Check if it's a supported image file
        final ext = path.toLowerCase().substring(path.lastIndexOf('.'));
        if (_supportedImageExtensions.contains(ext)) {
          newImages.add(file);
        }
      }
    }

    // Add new images, avoiding duplicates
    final existingPaths = _images.map((f) => f.path).toSet();
    final uniqueNewImages = newImages.where((f) => !existingPaths.contains(f.path)).toList();

    setState(() {
      _images.addAll(uniqueNewImages);
      _isScanning = false;
    });

    if (uniqueNewImages.isNotEmpty && _nameController.text.isEmpty && _images.isNotEmpty) {
      // Try to derive a name from the first image's parent folder
      final parentDir = _images.first.parent.path.split(Platform.pathSeparator).last;
      _nameController.text = parentDir;
    }
  }

  void _removeImage(int index) {
    if (index < 0 || index >= _images.length) return;
    setState(() {
      _images.removeAt(index);
    });
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
  }

  void _showCarousel(int initialIndex) {
    if (_images.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ImageCarouselOverlay(
            images: _images,
            initialIndex: initialIndex,
            onRemove: (index) {
              _removeImage(index);
              if (_images.isEmpty) {
                Navigator.of(context).pop();
              }
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _importGallery() async {
    if (_images.isEmpty) return;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a gallery name')),
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _importProgress = 0;
      _importTotal = _images.length;
    });

    try {
      // Use selected folder or derive from first image's parent directory
      final folderPath = _selectedFolder ?? _images.first.parent.path;

      await context.read<AppState>().importGallery(
        name: _nameController.text.trim(),
        folderPath: folderPath,
        images: _images,
        onProgress: (current, total) {
          setState(() {
            _importProgress = current;
            _importTotal = total;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gallery imported successfully!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Gallery'),
      ),
      body: DropTarget(
        onDragDone: (details) => _handleDroppedFiles([details]),
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        child: Stack(
          children: [
            SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step 1: Select folder
                _StepCard(
                  number: '1',
                  title: 'Select Photo Folder',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedFolder != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.folder,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedFolder!,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      OutlinedButton.icon(
                        onPressed: _isImporting ? null : _selectFolder,
                        icon: const Icon(Icons.folder_open),
                        label: Text(
                          _selectedFolder == null
                              ? 'Browse...'
                              : 'Change Folder',
                        ),
                      ),
                      if (_isScanning) ...[
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Scanning for images...'),
                          ],
                        ),
                      ],
                      if (_images.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF16A34A),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_images.length} images selected',
                              style: const TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_images.isEmpty && !_isScanning) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.drag_indicator,
                                size: 32,
                                color: Color(0xFF94A3B8),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Or drag & drop images/folders here',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Step 2: Name gallery
                _StepCard(
                  number: '2',
                  title: 'Name Your Gallery',
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Wedding 2024',
                      helperText: 'This name will be shown to your clients',
                    ),
                    enabled: !_isImporting,
                  ),
                ),
                const SizedBox(height: 16),

                // Preview with drag-to-reorder and remove buttons
                if (_images.isNotEmpty) ...[
                  _StepCard(
                    number: '3',
                    title: 'Preview & Arrange',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Drag images to reorder. Click to view full size. Click X to remove.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _DraggableImageGrid(
                          images: _images,
                          onReorder: _reorderImages,
                          onRemove: _removeImage,
                          onTap: _showCarousel,
                          enabled: !_isImporting,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Import progress
                if (_isImporting) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Processing images...',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              '$_importProgress / $_importTotal',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _importTotal > 0
                              ? _importProgress / _importTotal
                              : 0,
                          backgroundColor: const Color(0xFFBFDBFE),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Import button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_images.isNotEmpty &&
                            !_isImporting &&
                            _nameController.text.trim().isNotEmpty)
                        ? _importGallery
                        : null,
                    child: const Text('Import Gallery'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
            // Drag overlay
            if (_isDragging)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2563EB),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 64,
                            color: Color(0xFF2563EB),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Drop images or folders here',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Supports JPG, PNG, GIF, WebP, BMP',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Draggable grid of images with remove buttons
class _DraggableImageGrid extends StatefulWidget {
  final List<File> images;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onRemove;
  final void Function(int index) onTap;
  final bool enabled;

  const _DraggableImageGrid({
    required this.images,
    required this.onReorder,
    required this.onRemove,
    required this.onTap,
    required this.enabled,
  });

  @override
  State<_DraggableImageGrid> createState() => _DraggableImageGridState();
}

class _DraggableImageGridState extends State<_DraggableImageGrid> {
  int? _draggedIndex;

  @override
  Widget build(BuildContext context) {
    const double itemSize = 120;
    const double spacing = 8;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / (itemSize + spacing)).floor().clamp(3, 6);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(_images.length, (index) {
            final file = _images[index];
            final isDragged = _draggedIndex == index;

            return Draggable<int>(
              data: index,
              feedback: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: _ImageTile(
                  file: file,
                  size: itemSize,
                  showRemoveButton: false,
                  opacity: 0.9,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _ImageTile(
                  file: file,
                  size: itemSize,
                  showRemoveButton: false,
                ),
              ),
              onDragStarted: () {
                setState(() => _draggedIndex = index);
              },
              onDragEnd: (_) {
                setState(() => _draggedIndex = null);
              },
              child: DragTarget<int>(
                onAcceptWithDetails: (details) {
                  widget.onReorder(details.data, index);
                },
                onWillAcceptWithDetails: (details) {
                  return details.data != index;
                },
                builder: (context, candidateData, rejectedData) {
                  final isHovered = candidateData.isNotEmpty;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    transform: isHovered
                        ? (Matrix4.identity()..scale(1.05))
                        : Matrix4.identity(),
                    child: _ImageTile(
                      file: file,
                      size: itemSize,
                      showRemoveButton: widget.enabled,
                      onRemove: () => widget.onRemove(index),
                      onTap: () => widget.onTap(index),
                      highlighted: isHovered,
                    ),
                  );
                },
              ),
            );
          }),
        );
      },
    );
  }

  List<File> get _images => widget.images;
}

/// Single image tile with optional remove button
class _ImageTile extends StatefulWidget {
  final File file;
  final double size;
  final bool showRemoveButton;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  final double opacity;
  final bool highlighted;

  const _ImageTile({
    required this.file,
    required this.size,
    this.showRemoveButton = true,
    this.onRemove,
    this.onTap,
    this.opacity = 1.0,
    this.highlighted = false,
  });

  @override
  State<_ImageTile> createState() => _ImageTileState();
}

class _ImageTileState extends State<_ImageTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Opacity(
          opacity: widget.opacity,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.highlighted
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE2E8F0),
                width: widget.highlighted ? 2 : 1,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.file(
                    widget.file,
                    fit: BoxFit.cover,
                    cacheWidth: 240,
                  ),
                ),
                // Remove button
                if (widget.showRemoveButton)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _isHovered ? 1.0 : 0.0,
                      child: _RemoveButton(onPressed: widget.onRemove),
                    ),
                  ),
                // Index badge
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.file.path.split(Platform.pathSeparator).last,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Remove button widget
class _RemoveButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _RemoveButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFDC2626),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          width: 24,
          height: 24,
          child: Icon(
            Icons.close,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Full-screen carousel overlay for viewing images
class _ImageCarouselOverlay extends StatefulWidget {
  final List<File> images;
  final int initialIndex;
  final void Function(int index) onRemove;

  const _ImageCarouselOverlay({
    required this.images,
    required this.initialIndex,
    required this.onRemove,
  });

  @override
  State<_ImageCarouselOverlay> createState() => _ImageCarouselOverlayState();
}

class _ImageCarouselOverlayState extends State<_ImageCarouselOverlay> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (index < 0 || index >= widget.images.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _goToPage(_currentIndex - 1);
    }
  }

  void _nextImage() {
    if (_currentIndex < widget.images.length - 1) {
      _goToPage(_currentIndex + 1);
    }
  }

  void _removeCurrentImage() {
    widget.onRemove(_currentIndex);
    // Adjust current index if needed
    if (_currentIndex >= widget.images.length && widget.images.isNotEmpty) {
      setState(() {
        _currentIndex = widget.images.length - 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background tap to close
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.transparent),
          ),

          // Image carousel
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    widget.images[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),

          // Top bar with close and remove buttons
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54,
                    Colors.black.withValues(alpha: 0),
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close button
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Close',
                    ),
                    // Image counter
                    Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Remove button
                    IconButton(
                      onPressed: _removeCurrentImage,
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                      tooltip: 'Remove from gallery',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom bar with filename and thumbnail strip
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black54,
                    Colors.black.withValues(alpha: 0),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Filename
                    Text(
                      widget.images[_currentIndex].path.split(Platform.pathSeparator).last,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Thumbnail strip
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.images.length,
                        itemBuilder: (context, index) {
                          final isSelected = index == _currentIndex;
                          return GestureDetector(
                            onTap: () => _goToPage(index),
                            child: Container(
                              width: 60,
                              height: 60,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : Colors.white30,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Opacity(
                                  opacity: isSelected ? 1.0 : 0.6,
                                  child: Image.file(
                                    widget.images[index],
                                    fit: BoxFit.cover,
                                    cacheWidth: 120,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Left navigation arrow
          if (_currentIndex > 0)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavigationArrow(
                  icon: Icons.chevron_left,
                  onPressed: _previousImage,
                ),
              ),
            ),

          // Right navigation arrow
          if (_currentIndex < widget.images.length - 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavigationArrow(
                  icon: Icons.chevron_right,
                  onPressed: _nextImage,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Navigation arrow button
class _NavigationArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _NavigationArrow({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final Widget child;

  const _StepCard({
    required this.number,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
