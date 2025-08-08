import 'package:flutter/material.dart';
import '../services/offline_queue_service.dart';

/// Widget that displays the status of the offline operation queue.
/// 
/// Shows information about pending operations, failed operations,
/// and provides controls for manual queue processing and clearing.
class OfflineQueueStatusWidget extends StatefulWidget {
  const OfflineQueueStatusWidget({super.key});

  @override
  State<OfflineQueueStatusWidget> createState() => _OfflineQueueStatusWidgetState();
}

class _OfflineQueueStatusWidgetState extends State<OfflineQueueStatusWidget> {
  final OfflineQueueService _queueService = OfflineQueueService();
  OfflineQueueStatus? _status;
  
  @override
  void initState() {
    super.initState();
    _updateStatus();
  }

  void _updateStatus() {
    setState(() {
      _status = _queueService.getQueueStatus();
    });
  }

  Future<void> _processQueue() async {
    try {
      await _queueService.processQueue();
      _updateStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Queue processing initiated'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process queue: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _clearQueue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Offline Queue'),
        content: const Text(
          'This will remove all queued operations. '
          'Any unsaved journal entries or failed operations will be lost. '
          'Are you sure?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _queueService.clearQueue();
        _updateStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Queue cleared successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear queue: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    
    if (status == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading queue status...'),
            ],
          ),
        ),
      );
    }

    if (status.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 12),
              Text('All operations synchronized'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status.hasFailedOperations ? Icons.warning : Icons.sync,
                  color: status.hasFailedOperations ? Colors.orange : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Offline Queue Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (status.isProcessing) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  const Text('Processing...', style: TextStyle(fontSize: 12)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            
            // Status information
            _buildStatusRow('Total Operations', status.totalOperations.toString()),
            _buildStatusRow('Pending', status.pendingOperations.toString()),
            if (status.hasFailedOperations)
              _buildStatusRow(
                'Failed', 
                status.failedOperations.toString(),
                color: Colors.orange,
              ),
            
            if (status.lastProcessedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last processed: ${_formatDateTime(status.lastProcessedAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: status.isProcessing ? null : _processQueue,
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('Process Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: status.isProcessing ? null : _clearQueue,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear Queue'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _updateStatus,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh status',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Compact version of the queue status for showing in app bars or headers
class CompactOfflineQueueIndicator extends StatefulWidget {
  final VoidCallback? onTap;
  
  const CompactOfflineQueueIndicator({
    super.key,
    this.onTap,
  });

  @override
  State<CompactOfflineQueueIndicator> createState() => _CompactOfflineQueueIndicatorState();
}

class _CompactOfflineQueueIndicatorState extends State<CompactOfflineQueueIndicator> {
  final OfflineQueueService _queueService = OfflineQueueService();
  OfflineQueueStatus? _status;

  @override
  void initState() {
    super.initState();
    _updateStatus();
  }

  void _updateStatus() {
    setState(() {
      _status = _queueService.getQueueStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    
    if (status == null || status.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.onTap ?? _showQueueDetails,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: status.hasFailedOperations ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: status.hasFailedOperations ? Colors.orange : Colors.blue,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status.isProcessing ? Icons.sync : 
              status.hasFailedOperations ? Icons.warning : Icons.cloud_upload,
              size: 14,
              color: status.hasFailedOperations ? Colors.orange : Colors.blue,
            ),
            const SizedBox(width: 4),
            Text(
              '${status.totalOperations}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: status.hasFailedOperations ? Colors.orange : Colors.blue,
              ),
            ),
            if (status.isProcessing) ...[
              const SizedBox(width: 4),
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: status.hasFailedOperations ? Colors.orange : Colors.blue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showQueueDetails() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Offline Queue',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OfflineQueueStatusWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}