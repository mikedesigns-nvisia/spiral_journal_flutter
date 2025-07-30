import 'package:flutter/material.dart';
import '../services/ai_service_manager.dart';

/// Widget that displays network status for AI services and provides optimization info
class NetworkStatusWidget extends StatelessWidget {
  /// Whether to show as a compact indicator or full card
  final bool compact;
  
  /// Whether to show detailed network statistics
  final bool showDetails;
  
  /// AI service manager instance
  final AIServiceManager aiServiceManager;

  const NetworkStatusWidget({
    super.key,
    required this.aiServiceManager,
    this.compact = false,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NetworkStatus>(
      stream: aiServiceManager.networkStatusStream,
      initialData: aiServiceManager.currentNetworkStatus,
      builder: (context, snapshot) {
        final networkStatus = snapshot.data ?? NetworkStatus.unknown;
        
        if (compact) {
          return _buildCompactIndicator(context, networkStatus);
        } else {
          return _buildFullCard(context, networkStatus);
        }
      },
    );
  }

  Widget _buildCompactIndicator(BuildContext context, NetworkStatus status) {
    final theme = Theme.of(context);
    final networkStats = aiServiceManager.getNetworkStatistics();
    
    // Don't show indicator if on WiFi and no deferred requests
    if (status == NetworkStatus.wifi && networkStats.deferredRequestsCount == 0) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status, theme).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status, theme).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 14,
            color: _getStatusColor(status, theme),
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusText(status),
            style: theme.textTheme.labelSmall?.copyWith(
              color: _getStatusColor(status, theme),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (networkStats.deferredRequestsCount > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${networkStats.deferredRequestsCount}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullCard(BuildContext context, NetworkStatus status) {
    final theme = Theme.of(context);
    final networkStats = aiServiceManager.getNetworkStatistics();
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status, theme),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Analysis Network Status',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: _getStatusColor(status, theme),
                        ),
                      ),
                      Text(
                        _getDetailedStatusMessage(status, networkStats),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showDetails) ...[
              const SizedBox(height: 16),
              _buildNetworkDetails(context, status, networkStats),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkDetails(BuildContext context, NetworkStatus status, NetworkStatistics stats) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            context,
            'Connection Type',
            _getStatusText(status),
            _getStatusIcon(status),
            _getStatusColor(status, theme),
          ),
          if (stats.deferredRequestsCount > 0) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              'Deferred Requests',
              '${stats.deferredRequestsCount}',
              Icons.schedule,
              Colors.orange,
            ),
          ],
          if (stats.isPreFetching) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              'Status',
              'Pre-fetching insights',
              Icons.cloud_sync,
              Colors.blue,
            ),
          ],
          const SizedBox(height: 8),
          _buildDetailRow(
            context,
            'Processing Mode',
            _getProcessingMode(status),
            _getProcessingIcon(status),
            _getProcessingColor(status, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.wifi:
        return Icons.wifi;
      case NetworkStatus.cellular:
        return Icons.signal_cellular_4_bar;
      case NetworkStatus.offline:
        return Icons.wifi_off;
      case NetworkStatus.unknown:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(NetworkStatus status, ThemeData theme) {
    switch (status) {
      case NetworkStatus.wifi:
        return Colors.green;
      case NetworkStatus.cellular:
        return Colors.orange;
      case NetworkStatus.offline:
        return theme.colorScheme.error;
      case NetworkStatus.unknown:
        return theme.colorScheme.outline;
    }
  }

  String _getStatusText(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.wifi:
        return 'WiFi';
      case NetworkStatus.cellular:
        return 'Cellular';
      case NetworkStatus.offline:
        return 'Offline';
      case NetworkStatus.unknown:
        return 'Unknown';
    }
  }

  String _getDetailedStatusMessage(NetworkStatus status, NetworkStatistics stats) {
    switch (status) {
      case NetworkStatus.wifi:
        if (stats.isPreFetching) {
          return 'Connected via WiFi. Pre-fetching insights during idle time.';
        }
        return 'Connected via WiFi. All AI features available with enhanced batching.';
      case NetworkStatus.cellular:
        if (stats.deferredRequestsCount > 0) {
          return 'Connected via cellular. ${stats.deferredRequestsCount} non-critical analysis requests deferred for WiFi.';
        }
        return 'Connected via cellular. Non-critical AI analysis deferred to preserve data.';
      case NetworkStatus.offline:
        return 'No connection. AI analysis queued for when connectivity returns.';
      case NetworkStatus.unknown:
        return 'Connection status unknown. AI features may be limited.';
    }
  }

  String _getProcessingMode(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.wifi:
        return 'Full Processing + Batching';
      case NetworkStatus.cellular:
        return 'Critical Only';
      case NetworkStatus.offline:
        return 'Queued for Later';
      case NetworkStatus.unknown:
        return 'Limited';
    }
  }

  IconData _getProcessingIcon(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.wifi:
        return Icons.bolt;
      case NetworkStatus.cellular:
        return Icons.data_saver_on;
      case NetworkStatus.offline:
        return Icons.pause_circle_outline;
      case NetworkStatus.unknown:
        return Icons.warning_amber;
    }
  }

  Color _getProcessingColor(NetworkStatus status, ThemeData theme) {
    switch (status) {
      case NetworkStatus.wifi:
        return Colors.green;
      case NetworkStatus.cellular:
        return Colors.amber;
      case NetworkStatus.offline:
        return theme.colorScheme.outline;
      case NetworkStatus.unknown:
        return Colors.orange;
    }
  }
}

/// Simplified network status indicator for app bars
class NetworkStatusIndicator extends StatelessWidget {
  final AIServiceManager aiServiceManager;

  const NetworkStatusIndicator({
    super.key,
    required this.aiServiceManager,
  });

  @override
  Widget build(BuildContext context) {
    return NetworkStatusWidget(
      aiServiceManager: aiServiceManager,
      compact: true,
    );
  }
}