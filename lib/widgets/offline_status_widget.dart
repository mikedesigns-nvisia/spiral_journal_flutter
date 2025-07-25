import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/core_provider_refactored.dart';
import '../services/core_offline_support_service.dart';
import '../models/core_error.dart';

/// Widget that displays offline status and provides recovery options
class OfflineStatusWidget extends StatelessWidget {
  /// Whether to show the widget as a banner at the top
  final bool showAsBanner;
  
  /// Whether to show detailed status information
  final bool showDetails;
  
  /// Callback when user requests to go online
  final VoidCallback? onGoOnline;
  
  /// Callback when user requests to work offline
  final VoidCallback? onWorkOffline;

  const OfflineStatusWidget({
    super.key,
    this.showAsBanner = false,
    this.showDetails = false,
    this.onGoOnline,
    this.onWorkOffline,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CoreProvider>(
      builder: (context, coreProvider, child) {
        final offlineStatus = coreProvider.offlineStatus;
        
        // Don't show anything if we're online and not in offline mode
        if (offlineStatus.isConnected && !offlineStatus.isOfflineModeEnabled) {
          return const SizedBox.shrink();
        }
        
        if (showAsBanner) {
          return _buildBanner(context, offlineStatus, coreProvider);
        } else {
          return _buildCard(context, offlineStatus, coreProvider);
        }
      },
    );
  }

  Widget _buildBanner(BuildContext context, OfflineStatus status, CoreProvider provider) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: status.isConnected 
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.errorContainer,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            status.isConnected 
                ? Icons.cloud_off_outlined
                : Icons.wifi_off_outlined,
            size: 20,
            color: status.isConnected 
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getStatusMessage(status),
              style: theme.textTheme.bodySmall?.copyWith(
                color: status.isConnected 
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (status.queuedOperationsCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${status.queuedOperationsCount}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          _buildActionButton(context, status, provider),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, OfflineStatus status, CoreProvider provider) {
    final theme = Theme.of(context);
    
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
                  status.isConnected 
                      ? Icons.cloud_off_outlined
                      : Icons.wifi_off_outlined,
                  color: status.isConnected 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status.isConnected ? 'Offline Mode' : 'No Connection',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: status.isConnected 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusMessage(status),
              style: theme.textTheme.bodyMedium,
            ),
            if (showDetails) ...[
              const SizedBox(height: 12),
              _buildStatusDetails(context, status),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!status.isConnected) ...[
                  TextButton(
                    onPressed: () => _checkConnection(context, provider),
                    child: const Text('Check Connection'),
                  ),
                  const SizedBox(width: 8),
                ],
                _buildActionButton(context, status, provider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDetails(BuildContext context, OfflineStatus status) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            context,
            'Connection Status',
            status.isConnected ? 'Connected' : 'Disconnected',
            status.isConnected ? Icons.check_circle : Icons.error,
            status.isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            context,
            'Offline Mode',
            status.isOfflineModeEnabled ? 'Enabled' : 'Disabled',
            status.isOfflineModeEnabled ? Icons.cloud_off : Icons.cloud,
            status.isOfflineModeEnabled ? Colors.orange : Colors.blue,
          ),
          if (status.queuedOperationsCount > 0) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              'Queued Operations',
              '${status.queuedOperationsCount}',
              Icons.queue,
              Colors.amber,
            ),
          ],
          const SizedBox(height: 8),
          _buildDetailRow(
            context,
            'Offline Data',
            status.hasOfflineData ? 'Available' : 'Not Available',
            status.hasOfflineData ? Icons.storage : Icons.warning,
            status.hasOfflineData ? Colors.green : Colors.orange,
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
        Text(
          value,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, OfflineStatus status, CoreProvider provider) {
    if (status.isConnected && status.isOfflineModeEnabled) {
      // Connected but in offline mode - offer to go online
      return ElevatedButton(
        onPressed: () => _goOnline(context, provider),
        child: const Text('Go Online'),
      );
    } else if (!status.isConnected) {
      // Not connected - offer to work offline
      return ElevatedButton(
        onPressed: status.hasOfflineData 
            ? () => _workOffline(context, provider)
            : null,
        child: const Text('Work Offline'),
      );
    } else {
      // Connected and online - offer to go offline
      return TextButton(
        onPressed: () => _goOffline(context, provider),
        child: const Text('Go Offline'),
      );
    }
  }

  String _getStatusMessage(OfflineStatus status) {
    if (!status.isConnected) {
      if (status.hasOfflineData) {
        return 'No internet connection. You can continue working with cached data.';
      } else {
        return 'No internet connection and no offline data available. Please connect to sync your data.';
      }
    } else if (status.isOfflineModeEnabled) {
      return 'Offline mode is enabled. Your changes will sync when you go online.';
    } else {
      return 'Connected and online.';
    }
  }

  Future<void> _checkConnection(BuildContext context, CoreProvider provider) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Checking connection...'),
          ],
        ),
      ),
    );

    try {
      // Force connectivity check
      final isConnected = await provider._offlineService.checkConnectivity();
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isConnected 
                  ? 'Connection restored!' 
                  : 'Still no connection. You can continue working offline.',
            ),
            backgroundColor: isConnected ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to check connection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _goOnline(BuildContext context, CoreProvider provider) async {
    await provider.setOfflineMode(false);
    onGoOnline?.call();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Switched to online mode'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _goOffline(BuildContext context, CoreProvider provider) async {
    await provider.setOfflineMode(true);
    onWorkOffline?.call();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Switched to offline mode'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _workOffline(BuildContext context, CoreProvider provider) async {
    // This doesn't change the offline mode, just acknowledges working offline
    onWorkOffline?.call();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Continuing with offline data'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
}

/// Simplified offline indicator for use in app bars
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CoreProvider>(
      builder: (context, coreProvider, child) {
        final offlineStatus = coreProvider.offlineStatus;
        
        if (offlineStatus.isConnected && !offlineStatus.isOfflineModeEnabled) {
          return const SizedBox.shrink();
        }
        
        final theme = Theme.of(context);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: offlineStatus.isConnected 
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                offlineStatus.isConnected 
                    ? Icons.cloud_off
                    : Icons.wifi_off,
                size: 14,
                color: offlineStatus.isConnected 
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 4),
              Text(
                offlineStatus.isConnected ? 'Offline' : 'No Connection',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: offlineStatus.isConnected 
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onErrorContainer,
                ),
              ),
              if (offlineStatus.queuedOperationsCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${offlineStatus.queuedOperationsCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}