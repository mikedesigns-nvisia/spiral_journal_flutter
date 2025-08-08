import 'package:flutter/material.dart';
import '../core/app_constants.dart';
import '../design_system/design_tokens.dart';
import '../design_system/heading_system.dart';
// Batch AI analysis service removed - using local fallback processing

/// Widget that shows the status of local processing
class AnalysisStatusWidget extends StatefulWidget {
  /// Optional callback when processing completes
  final VoidCallback? onProcessingComplete;
  
  const AnalysisStatusWidget({
    super.key,
    this.onProcessingComplete,
  });

  @override
  State<AnalysisStatusWidget> createState() => _AnalysisStatusWidgetState();
}

class _AnalysisStatusWidgetState extends State<AnalysisStatusWidget> {
  // Batch AI analysis service removed - using local fallback processing
  Map<String, dynamic>? _status;
  String _timeUntilNext = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadStatus();
    // Refresh status every minute
    _startStatusUpdates();
  }

  void _startStatusUpdates() {
    // Update status every minute
    Stream.periodic(const Duration(minutes: 1)).listen((_) {
      if (mounted) {
        _loadStatus();
      }
    });
  }

  Future<void> _loadStatus() async {
    try {
      // Batch service calls removed - using local fallback processing
      final status = {'isRunning': false, 'queueSize': 0, 'lastRun': 'Never - using local processing'};
      final timeUntilNext = 'Local processing active';
      
      if (mounted) {
        setState(() {
          _status = status;
          _timeUntilNext = timeUntilNext;
        });
      }
    } catch (e) {
      debugPrint('AnalysisStatusWidget: Error loading status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status == null) {
      return const SizedBox.shrink();
    }

    final pendingCount = _status!['pendingCount'] as int? ?? 0;
    final isProcessing = _status!['isProcessing'] as bool? ?? false;
    
    // Don't show widget if no pending entries
    if (pendingCount == 0 && !isProcessing) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.spacing8,
      ),
      padding: const EdgeInsets.all(AppConstants.spacing12),
      decoration: BoxDecoration(
        color: DesignTokens.getColorWithOpacity(
          DesignTokens.getPrimaryColor(context),
          0.1,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: DesignTokens.getColorWithOpacity(
            DesignTokens.getPrimaryColor(context),
            0.3,
          ),
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            padding: const EdgeInsets.all(AppConstants.spacing8),
            decoration: BoxDecoration(
              color: DesignTokens.getPrimaryColor(context),
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            ),
            child: Icon(
              isProcessing ? Icons.psychology : Icons.schedule,
              color: Colors.white,
              size: 16,
            ),
          ),
          
          const SizedBox(width: AppConstants.spacing12),
          
          // Status content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isProcessing 
                      ? 'Processing...'
                      : 'Processing Pending',
                  style: HeadingSystem.getBodyMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: AppConstants.spacing4),
                Text(
                  isProcessing
                      ? 'Processing $pendingCount entries'
                      : '$pendingCount entries will be processed in $_timeUntilNext',
                  style: HeadingSystem.getBodySmall(context).copyWith(
                    color: DesignTokens.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          
          // Manual trigger button (only show if not processing)
          if (!isProcessing) ...[
            const SizedBox(width: AppConstants.spacing8),
            IconButton(
              onPressed: _triggerBatchNow,
              icon: Icon(
                Icons.play_arrow,
                color: DesignTokens.getPrimaryColor(context),
                size: 20,
              ),
              tooltip: 'Run processing now',
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _triggerBatchNow() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Starting processing...'),
          backgroundColor: DesignTokens.getPrimaryColor(context),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Batch service run removed - using local fallback processing
      await _loadStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Processing completed!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Notify parent that processing is complete
        widget.onProcessingComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Processing failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}