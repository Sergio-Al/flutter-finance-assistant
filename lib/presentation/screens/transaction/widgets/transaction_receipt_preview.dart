import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Preview widget for transaction receipt images with zoom capability.
class TransactionReceiptPreview extends StatelessWidget {
  final String? imageUrl;
  final String? localPath;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool isLoading;
  final bool compact;

  const TransactionReceiptPreview({
    super.key,
    this.imageUrl,
    this.localPath,
    this.onTap,
    this.onRemove,
    this.isLoading = false,
    this.compact = false,
  });

  bool get hasImage => imageUrl != null || localPath != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (compact) {
      return _buildCompactPreview(context, isDark);
    }

    return GlassCard(
      onTap: hasImage ? onTap : null,
      padding: EdgeInsets.zero,
      child: hasImage
          ? _buildImagePreview(context, isDark)
          : _buildEmptyState(context, isDark),
    );
  }

  Widget _buildCompactPreview(BuildContext context, bool isDark) {
    if (!hasImage) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(),
              // Receipt icon overlay
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black54 : Colors.white70,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    size: 12,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context, bool isDark) {
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: isLoading ? _buildLoadingState(isDark) : _buildImage(),
          ),
        ),

        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ),

        // Bottom label
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Row(
            children: [
              Icon(
                Icons.receipt_long,
                size: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              Text(
                'Receipt attached',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.zoom_in,
                size: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),

        // Remove button
        if (onRemove != null)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage() {
    if (localPath != null) {
      return Image.file(
        File(localPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorState(),
      );
    }

    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingState(
            Theme.of(context).brightness == Brightness.dark,
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorState(),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No receipt attached',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      color: isDark ? Colors.grey[900] : Colors.grey[100],
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
      ),
    );
  }
}

/// Full-screen receipt viewer with zoom and pan.
class ReceiptFullScreenViewer extends StatefulWidget {
  final String? imageUrl;
  final String? localPath;
  final String? merchantName;
  final DateTime? date;

  const ReceiptFullScreenViewer({
    super.key,
    this.imageUrl,
    this.localPath,
    this.merchantName,
    this.date,
  });

  static Future<void> show(
    BuildContext context, {
    String? imageUrl,
    String? localPath,
    String? merchantName,
    DateTime? date,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => ReceiptFullScreenViewer(
          imageUrl: imageUrl,
          localPath: localPath,
          merchantName: merchantName,
          date: date,
        ),
      ),
    );
  }

  @override
  State<ReceiptFullScreenViewer> createState() =>
      _ReceiptFullScreenViewerState();
}

class _ReceiptFullScreenViewerState extends State<ReceiptFullScreenViewer> {
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.merchantName ?? 'Receipt',
              style: const TextStyle(fontSize: 16),
            ),
            if (widget.date != null)
              Text(
                _formatDate(widget.date!),
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
          ],
        ),
        actions: [
          // Zoom controls
          IconButton(icon: const Icon(Icons.zoom_out), onPressed: _zoomOut),
          IconButton(icon: const Icon(Icons.zoom_in), onPressed: _zoomIn),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetZoom),
        ],
      ),
      body: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 4.0,
        onInteractionUpdate: (details) {
          setState(() {
            _currentScale = _transformationController.value.getMaxScaleOnAxis();
          });
        },
        child: Center(child: _buildImage()),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(_currentScale * 100).toInt()}%',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.localPath != null) {
      return Image.file(File(widget.localPath!), fit: BoxFit.contain);
    }

    if (widget.imageUrl != null) {
      return Image.network(
        widget.imageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
      );
    }

    return const Icon(
      Icons.receipt_long_outlined,
      size: 64,
      color: Colors.grey,
    );
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.5).clamp(0.5, 4.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
    setState(() => _currentScale = newScale);
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.5).clamp(0.5, 4.0);
    _transformationController.value = Matrix4.identity()..scale(newScale);
    setState(() => _currentScale = newScale);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() => _currentScale = 1.0);
  }

  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

/// Small receipt indicator badge.
class ReceiptBadge extends StatelessWidget {
  final bool hasReceipt;
  final VoidCallback? onTap;

  const ReceiptBadge({super.key, this.hasReceipt = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (!hasReceipt) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.info.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 10, color: AppTheme.info),
            const SizedBox(width: 2),
            Text(
              'Receipt',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppTheme.info,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
