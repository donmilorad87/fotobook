import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../models/gallery.dart';

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
                  if (!gallery.isSubmitted)
                    TextButton.icon(
                      onPressed: _isSubmitting ? null : _submitGallery,
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
                      child: _PicturesGrid(gallery: gallery),
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

  const _PicturesGrid({required this.gallery});

  @override
  Widget build(BuildContext context) {
    final pictures = gallery.pictures ?? [];

    if (pictures.isEmpty) {
      return const Center(
        child: Text('No pictures in this gallery'),
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

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              fit: StackFit.expand,
              children: [
                FutureBuilder<bool>(
                  future: file.exists(),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return Image.file(
                        file,
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
                      picture.fileName,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
