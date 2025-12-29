import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../state/app_state.dart';
import '../models/gallery.dart';
import '../models/picture.dart';
import '../widgets/lightbox.dart';

class GalleryDetailScreen extends StatefulWidget {
  final int galleryId;

  const GalleryDetailScreen({
    super.key,
    required this.galleryId,
  });

  @override
  State<GalleryDetailScreen> createState() => _GalleryDetailScreenState();
}

class _GalleryDetailScreenState extends State<GalleryDetailScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isAddingPictures = false;
  String _submitStatus = '';
  int _submitProgress = 0;
  int _submitTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    setState(() => _isLoading = true);
    await context.read<AppState>().selectGallery(widget.galleryId);
    setState(() => _isLoading = false);
  }

  Future<void> _submitGallery() async {
    setState(() {
      _isSubmitting = true;
      _submitStatus = 'Starting...';
      _submitProgress = 0;
      _submitTotal = 0;
    });

    try {
      await context.read<AppState>().submitGallery(
        widget.galleryId,
        onProgress: (current, total, status) {
          setState(() {
            _submitProgress = current;
            _submitTotal = total;
            _submitStatus = status;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gallery uploaded successfully!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _addPictures() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _isAddingPictures = true);

    try {
      final files = result.files
          .where((f) => f.path != null)
          .map((f) => File(f.path!))
          .toList();

      await context.read<AppState>().addPicturesToGallery(
        galleryId: widget.galleryId,
        images: files,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${files.length} picture(s)'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
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
        setState(() => _isAddingPictures = false);
      }
    }
  }

  Future<void> _deletePicture(Picture picture) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Picture'),
        content: Text(
          'Remove "${picture.fileName}" from this gallery?\n\n'
          'The original file will NOT be deleted from your computer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<AppState>().removePictureFromGallery(
          galleryId: widget.galleryId,
          pictureId: picture.id,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Picture removed')),
          );
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
      }
    }
  }

  Future<void> _deleteGallery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Gallery'),
        content: const Text(
          'Are you sure you want to delete this gallery from the app?\n\n'
          'This will only remove the gallery from Fotobook. '
          'Your original photos will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AppState>().deleteGallery(widget.galleryId);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _copyPublicUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL copied to clipboard')),
    );
  }

  void _openLightbox(List<Picture> pictures, int index) {
    Lightbox.show(
      context,
      pictures: pictures,
      initialIndex: index,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AppState>(
          builder: (context, appState, _) {
            return Text(appState.selectedGallery?.name ?? 'Gallery');
          },
        ),
        actions: [
          Consumer<AppState>(
            builder: (context, appState, _) {
              final gallery = appState.selectedGallery;
              if (gallery == null) return const SizedBox.shrink();

              return Row(
                children: [
                  // Add Pictures button (only for local galleries)
                  if (!gallery.isSubmitted)
                    TextButton.icon(
                      onPressed: _isAddingPictures || _isSubmitting
                          ? null
                          : _addPictures,
                      icon: _isAddingPictures
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Add Pictures'),
                    ),
                  if (!gallery.isSubmitted) const SizedBox(width: 8),
                  // Upload button (only for local galleries)
                  if (!gallery.isSubmitted)
                    TextButton.icon(
                      onPressed: _isSubmitting || _isAddingPictures
                          ? null
                          : _submitGallery,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Upload'),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _deleteGallery,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete gallery',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<AppState>(
              builder: (context, appState, _) {
                final gallery = appState.selectedGallery;
                if (gallery == null) {
                  return const Center(
                    child: Text('Gallery not found'),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gallery info bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        children: [
                          _InfoChip(
                            icon: Icons.photo_outlined,
                            label: '${gallery.pictureCount} photos',
                          ),
                          const SizedBox(width: 16),
                          _InfoChip(
                            icon: Icons.folder_outlined,
                            label: gallery.folderPath,
                          ),
                          const Spacer(),
                          if (gallery.isSubmitted && gallery.publicUrl.isNotEmpty) ...[
                            TextButton.icon(
                              onPressed: () => _copyPublicUrl(gallery.publicUrl),
                              icon: const Icon(Icons.link, size: 18),
                              label: const Text('Copy Public URL'),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Upload progress
                    if (_isSubmitting)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFBFDBFE)),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _submitStatus,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (_submitTotal > 0)
                                  Text(
                                    '$_submitProgress / $_submitTotal',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                              ],
                            ),
                            if (_submitTotal > 0) ...[
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: _submitProgress / _submitTotal,
                                backgroundColor: const Color(0xFFBFDBFE),
                              ),
                            ],
                          ],
                        ),
                      ),

                    // Pictures grid
                    Expanded(
                      child: _PicturesGrid(
                        gallery: gallery,
                        onPictureTap: _openLightbox,
                        onPictureDelete: gallery.isSubmitted ? null : _deletePicture,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _PicturesGrid extends StatelessWidget {
  final Gallery gallery;
  final void Function(List<Picture> pictures, int index) onPictureTap;
  final void Function(Picture picture)? onPictureDelete;

  const _PicturesGrid({
    required this.gallery,
    required this.onPictureTap,
    this.onPictureDelete,
  });

  @override
  Widget build(BuildContext context) {
    final pictures = gallery.pictures ?? [];

    if (pictures.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No pictures in this gallery',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (!gallery.isSubmitted) ...[
              const SizedBox(height: 8),
              Text(
                'Click "Add Pictures" to add images',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: pictures.length,
      itemBuilder: (context, index) {
        final picture = pictures[index];
        final file = File(picture.filePath);

        return _PictureCard(
          picture: picture,
          file: file,
          onTap: () => onPictureTap(pictures, index),
          onDelete: onPictureDelete != null
              ? () => onPictureDelete!(picture)
              : null,
        );
      },
    );
  }
}

class _PictureCard extends StatefulWidget {
  final Picture picture;
  final File file;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _PictureCard({
    required this.picture,
    required this.file,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_PictureCard> createState() => _PictureCardState();
}

class _PictureCardState extends State<_PictureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                FutureBuilder<bool>(
                  future: widget.file.exists(),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return Image.file(
                        widget.file,
                        fit: BoxFit.cover,
                        cacheWidth: 400,
                      );
                    }
                    return Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF94A3B8),
                      ),
                    );
                  },
                ),

                // Filename overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
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
                    child: Text(
                      widget.picture.fileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Delete button (top-right, only when hovered and deletable)
                if (widget.onDelete != null && _isHovered)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: widget.onDelete,
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Hover overlay
                if (_isHovered)
                  Container(
                    color: Colors.black.withOpacity(0.1),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
