import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/file_service.dart';
import '../state/app_state.dart';

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

  Future<void> _importGallery() async {
    if (_selectedFolder == null || _images.isEmpty) return;
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
      await context.read<AppState>().importGallery(
        name: _nameController.text.trim(),
        folderPath: _selectedFolder!,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
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
                              'Found ${_images.length} images',
                              style: const TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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

                // Preview
                if (_images.isNotEmpty) ...[
                  _StepCard(
                    number: '3',
                    title: 'Preview',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'First few images from the folder:',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _images.length > 10 ? 10 : _images.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.file(
                                    _images[index],
                                    fit: BoxFit.cover,
                                    cacheWidth: 200,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_images.length > 10)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '...and ${_images.length - 10} more',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
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
                    onPressed: (_selectedFolder != null &&
                            _images.isNotEmpty &&
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
