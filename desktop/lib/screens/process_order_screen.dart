import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gallery.dart';
import '../services/order_service.dart';
import '../state/app_state.dart';

class ProcessOrderScreen extends StatefulWidget {
  const ProcessOrderScreen({super.key});

  @override
  State<ProcessOrderScreen> createState() => _ProcessOrderScreenState();
}

class _ProcessOrderScreenState extends State<ProcessOrderScreen> {
  bool _isLoading = false;
  bool _isCreatingZip = false;
  bool _isDragging = false;
  int _zipProgress = 0;
  int _zipTotal = 0;
  Gallery? _matchedGallery;
  String? _error;

  Future<void> _loadOrderJson() async {
    final orderService = context.read<OrderService>();
    final jsonPath = await orderService.pickOrderJsonFile();

    if (jsonPath == null) return;

    await _processJsonFile(jsonPath);
  }

  Future<void> _processJsonFile(String jsonPath) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _matchedGallery = null;
    });

    try {
      final appState = context.read<AppState>();
      await appState.loadOrderFromJson(jsonPath);

      // Try to find matching gallery
      final gallery = await appState.findMatchingGallery();
      if (gallery != null) {
        await appState.matchOrderToGallery(gallery);
        setState(() {
          _matchedGallery = gallery;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDroppedFiles(DropDoneDetails details) async {
    if (_isLoading || _isCreatingZip) return;

    // Find the first JSON file
    for (final xFile in details.files) {
      final path = xFile.path;
      if (path.toLowerCase().endsWith('.json')) {
        await _processJsonFile(path);
        return;
      }
    }

    // No JSON file found
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please drop a JSON order file'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  void _clearOrder() {
    context.read<AppState>().clearOrder();
    setState(() {
      _matchedGallery = null;
      _error = null;
    });
  }

  Future<void> _createZip() async {
    final appState = context.read<AppState>();
    final orderService = context.read<OrderService>();

    final outputPath = await orderService.pickSaveLocation(appState.currentOrder!);
    if (outputPath == null) return;

    setState(() {
      _isCreatingZip = true;
      _zipProgress = 0;
      _zipTotal = 0;
    });

    try {
      final zipPath = await appState.createOrderZip(
        outputPath: outputPath,
        onProgress: (current, total) {
          setState(() {
            _zipProgress = current;
            _zipTotal = total;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ZIP created: $zipPath'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        appState.clearOrder();
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
        setState(() => _isCreatingZip = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Process Order'),
      ),
      body: DropTarget(
        onDragDone: _handleDroppedFiles,
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Consumer<AppState>(
                    builder: (context, appState, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Step 1: Load order JSON
                          _StepCard(
                            number: '1',
                            title: 'Load Order JSON',
                            subtitle: 'Select or drag & drop the order JSON file',
                            trailing: appState.currentOrder != null
                                ? IconButton(
                                    onPressed: _isLoading || _isCreatingZip
                                        ? null
                                        : _clearOrder,
                                    icon: const Icon(Icons.close),
                                    tooltip: 'Clear order',
                                    style: IconButton.styleFrom(
                                      foregroundColor: const Color(0xFFDC2626),
                                    ),
                                  )
                                : null,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (appState.currentOrder != null) ...[
                                  _OrderInfoCard(
                                    orderId: appState.currentOrder!.id,
                                    clientName: appState.currentOrder!.clientName,
                                    clientEmail: appState.currentOrder!.clientEmail,
                                    galleryName: appState.currentOrder!.galleryName,
                                    selectedCount: appState.currentOrder!.selectedCount,
                                  ),
                                  const SizedBox(height: 12),
                                ] else ...[
                                  // Drop zone hint
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
                                          Icons.upload_file,
                                          size: 40,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Drag & drop order JSON file here',
                                          style: TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'or use the button below to browse',
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                OutlinedButton.icon(
                                  onPressed: _isLoading || _isCreatingZip
                                      ? null
                                      : _loadOrderJson,
                                  icon: const Icon(Icons.file_open_outlined),
                                  label: Text(
                                    appState.currentOrder == null
                                        ? 'Browse for JSON File'
                                        : 'Load Different Order',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Step 2: Match gallery (automatic)
                          if (appState.currentOrder != null) ...[
                            _StepCard(
                              number: '2',
                              title: 'Local Gallery',
                              subtitle: _matchedGallery != null
                                  ? 'Matched automatically'
                                  : 'No matching gallery found',
                              child: _matchedGallery != null
                                  ? Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFF86EFAC),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF16A34A),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _matchedGallery!.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  _matchedGallery!.folderPath,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFFDE68A),
                                        ),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber,
                                            color: Color(0xFFD97706),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Gallery not found locally. Make sure you have imported the gallery before processing orders.',
                                              style: TextStyle(
                                                color: Color(0xFFD97706),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Step 3: Review matches
                          if (appState.matchedFiles != null) ...[
                            _StepCard(
                              number: '3',
                              title: 'Review Matched Files',
                              subtitle:
                                  '${appState.matchedFiles!.where((f) => f.exists).length} of ${appState.matchedFiles!.length} files found',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...appState.matchedFiles!.take(10).map((file) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            file.exists
                                                ? Icons.check_circle
                                                : Icons.error,
                                            size: 18,
                                            color: file.exists
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFFDC2626),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              file.filename,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: file.exists
                                                    ? null
                                                    : const Color(0xFFDC2626),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  if (appState.matchedFiles!.length > 10)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '...and ${appState.matchedFiles!.length - 10} more files',
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

                          // Error message
                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Loading indicator
                          if (_isLoading) ...[
                            const Center(child: CircularProgressIndicator()),
                            const SizedBox(height: 16),
                          ],

                          // ZIP progress
                          if (_isCreatingZip) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child:
                                            CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text('Creating ZIP archive...'),
                                      ),
                                      if (_zipTotal > 0)
                                        Text('$_zipProgress / $_zipTotal'),
                                    ],
                                  ),
                                  if (_zipTotal > 0) ...[
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: _zipProgress / _zipTotal,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Create ZIP button
                          if (appState.matchedFiles != null &&
                              appState.matchedFiles!.any((f) => f.exists))
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _isCreatingZip ? null : _createZip,
                                icon: const Icon(Icons.folder_zip),
                                label: const Text('Create ZIP Archive'),
                              ),
                            ),
                        ],
                      );
                    },
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
                            Icons.upload_file,
                            size: 64,
                            color: Color(0xFF2563EB),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Drop order JSON file here',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
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

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  const _StepCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
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

class _OrderInfoCard extends StatelessWidget {
  final int orderId;
  final String clientName;
  final String clientEmail;
  final String galleryName;
  final int selectedCount;

  const _OrderInfoCard({
    required this.orderId,
    required this.clientName,
    required this.clientEmail,
    required this.galleryName,
    required this.selectedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, size: 20),
              const SizedBox(width: 8),
              Text(
                'Order #$orderId',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Client', value: clientName),
          _InfoRow(label: 'Email', value: clientEmail),
          _InfoRow(label: 'Gallery', value: galleryName),
          _InfoRow(label: 'Selected', value: '$selectedCount photos'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

