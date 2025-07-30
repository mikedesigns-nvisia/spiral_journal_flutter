import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import '../utils/app_error_handler.dart';
import '../design_system/design_tokens.dart';
import '../design_system/component_library.dart';
import '../providers/core_provider_refactored.dart';

/// Comprehensive error handling UI components for user-friendly error management
/// Includes retry buttons, offline indicators, empty states, and graceful degradation

/// Enhanced retry button with loading states and smart retry logic
class RetryButton extends StatefulWidget {
  final VoidCallback? onRetry;
  final String text;
  final IconData? icon;
  final bool isLoading;
  final ButtonStyle? style;
  final bool enabled;
  final int maxRetries;
  final Duration retryDelay;

  const RetryButton({
    super.key,
    required this.onRetry,
    this.text = 'Try Again',
    this.icon = Icons.refresh,
    this.isLoading = false,
    this.style,
    this.enabled = true,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
  });

  @override
  State<RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<RetryButton> {
  int _retryCount = 0;
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    if (_retryCount >= widget.maxRetries || _isRetrying) return;

    setState(() {
      _isRetrying = true;
      _retryCount++;
    });

    try {
      // Add delay for better UX
      await Future.delayed(widget.retryDelay);
      widget.onRetry?.call();
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.enabled || 
                      _retryCount >= widget.maxRetries || 
                      widget.isLoading || 
                      _isRetrying;

    return ElevatedButton.icon(
      onPressed: isDisabled ? null : _handleRetry,
      icon: (_isRetrying || widget.isLoading)
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : Icon(widget.icon),
      label: Text(
        _retryCount >= widget.maxRetries 
            ? 'Max retries reached'
            : (_isRetrying || widget.isLoading)
                ? 'Retrying...'
                : _retryCount > 0
                    ? '${widget.text} (${_retryCount}/${widget.maxRetries})'
                    : widget.text,
      ),
      style: widget.style,
    );
  }
}

/// Enhanced connectivity status widget with real-time updates
class ConnectivityStatusWidget extends StatefulWidget {
  final bool showAsCard;
  final bool showDetails;
  final VoidCallback? onRetryConnection;
  final VoidCallback? onWorkOffline;

  const ConnectivityStatusWidget({
    super.key,
    this.showAsCard = false,
    this.showDetails = false,
    this.onRetryConnection,
    this.onWorkOffline,
  });

  @override
  State<ConnectivityStatusWidget> createState() => _ConnectivityStatusWidgetState();
}

class _ConnectivityStatusWidgetState extends State<ConnectivityStatusWidget> {
  late Stream<List<ConnectivityResult>> _connectivityStream;
  List<ConnectivityResult> _connectivityResult = [ConnectivityResult.none];

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged;
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _connectivityResult = result;
      });
    }
  }

  bool get _isConnected => 
      _connectivityResult.isNotEmpty && 
      !_connectivityResult.contains(ConnectivityResult.none);

  String get _connectionType {
    if (_connectivityResult.contains(ConnectivityResult.wifi)) return 'WiFi';
    if (_connectivityResult.contains(ConnectivityResult.mobile)) return 'Mobile';
    if (_connectivityResult.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    return 'None';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: _connectivityStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _connectivityResult = snapshot.data!;
        }

        if (_isConnected && !widget.showDetails) {
          return const SizedBox.shrink();
        }

        if (widget.showAsCard) {
          return _buildCard(context);
        } else {
          return _buildBanner(context);
        }
      },
    );
  }

  Widget _buildBanner(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = _isConnected 
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.errorContainer;
    final textColor = _isConnected 
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onErrorContainer;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.wifi : Icons.wifi_off,
            color: textColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isConnected 
                  ? 'Connected via $_connectionType'
                  : 'No internet connection',
              style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
            ),
          ),
          if (!_isConnected) ...[
            RetryButton(
              onRetry: widget.onRetryConnection ?? _retryConnection,
              text: 'Retry',
              icon: Icons.refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _isConnected 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 12),
                Text(
                  _isConnected ? 'Connected' : 'Offline',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _isConnected 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isConnected 
                  ? 'Connected to internet via $_connectionType'
                  : 'No internet connection. Some features may be limited.',
              style: theme.textTheme.bodyMedium,
            ),
            if (widget.showDetails) ...[
              const SizedBox(height: 16),
              _buildConnectionDetails(context),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_isConnected) ...[
                  TextButton(
                    onPressed: widget.onWorkOffline,
                    child: const Text('Work Offline'),
                  ),
                  const SizedBox(width: 8),
                  RetryButton(
                    onRetry: widget.onRetryConnection ?? _retryConnection,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionDetails(BuildContext context) {
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
          _buildDetailRow('Status', _isConnected ? 'Connected' : 'Disconnected'),
          _buildDetailRow('Type', _connectionType),
          _buildDetailRow('Last Check', DateTime.now().toString().substring(11, 19)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _retryConnection() async {
    await _initConnectivity();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isConnected 
                ? 'Connection restored!'
                : 'Still no connection',
          ),
          backgroundColor: _isConnected ? Colors.green : Colors.orange,
        ),
      );
    }
  }
}

/// Empty state widget with actionable suggestions
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final List<EmptyStateAction> actions;
  final Widget? illustration;
  final bool showAnimation;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actions = const [],
    this.illustration,
    this.showAnimation = true,
  });

  factory EmptyStateWidget.noJournalEntries({
    VoidCallback? onCreateEntry,
    VoidCallback? onImportEntries,
  }) {
    return EmptyStateWidget(
      title: 'No Journal Entries Yet',
      message: 'Start your mindfulness journey by creating your first journal entry. Reflect on your thoughts and feelings.',
      icon: Icons.edit_note_outlined,
      actions: [
        if (onCreateEntry != null)
          EmptyStateAction(
            label: 'Create First Entry',
            onTap: onCreateEntry,
            isPrimary: true,
            icon: Icons.add,
          ),
        if (onImportEntries != null)
          EmptyStateAction(
            label: 'Import Entries',
            onTap: onImportEntries,
            icon: Icons.upload_file,
          ),
      ],
    );
  }

  factory EmptyStateWidget.noConnection({
    VoidCallback? onRetry,
    VoidCallback? onWorkOffline,
  }) {
    return EmptyStateWidget(
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again, or continue working offline with limited features.',
      icon: Icons.wifi_off_outlined,
      actions: [
        if (onRetry != null)
          EmptyStateAction(
            label: 'Retry Connection',
            onTap: onRetry,
            isPrimary: true,
            icon: Icons.refresh,
          ),
        if (onWorkOffline != null)
          EmptyStateAction(
            label: 'Work Offline',
            onTap: onWorkOffline,
            icon: Icons.cloud_off,
          ),
      ],
    );
  }

  factory EmptyStateWidget.searchNoResults({
    required String searchTerm,
    VoidCallback? onClearSearch,
    VoidCallback? onBrowseAll,
  }) {
    return EmptyStateWidget(
      title: 'No Results Found',
      message: 'No entries match "$searchTerm". Try adjusting your search terms or browse all entries.',
      icon: Icons.search_off_outlined,
      actions: [
        if (onClearSearch != null)
          EmptyStateAction(
            label: 'Clear Search',
            onTap: onClearSearch,
            isPrimary: true,
            icon: Icons.clear,
          ),
        if (onBrowseAll != null)
          EmptyStateAction(
            label: 'Browse All Entries',
            onTap: onBrowseAll,
            icon: Icons.view_list,
          ),
      ],
    );
  }

  factory EmptyStateWidget.serviceUnavailable({
    required String serviceName,
    VoidCallback? onRetry,
    VoidCallback? onWorkOffline,
  }) {
    return EmptyStateWidget(
      title: '$serviceName Unavailable',
      message: 'The $serviceName service is currently unavailable. You can try again or continue with limited functionality.',
      icon: Icons.cloud_off_outlined,
      actions: [
        if (onRetry != null)
          EmptyStateAction(
            label: 'Retry',
            onTap: onRetry,
            isPrimary: true,
            icon: Icons.refresh,
          ),
        if (onWorkOffline != null)
          EmptyStateAction(
            label: 'Continue Offline',
            onTap: onWorkOffline,
            icon: Icons.offline_bolt,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (illustration != null)
              illustration!
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  icon,
                  size: 80,
                  color: theme.colorScheme.outline,
                ),
              ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: actions.map((action) => _buildAction(context, action)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, EmptyStateAction action) {
    if (action.isPrimary) {
      return ElevatedButton.icon(
        onPressed: action.onTap,
        icon: Icon(action.icon),
        label: Text(action.label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: action.onTap,
        icon: Icon(action.icon),
        label: Text(action.label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );
    }
  }
}

/// Action for empty state widgets
class EmptyStateAction {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isPrimary;

  const EmptyStateAction({
    required this.label,
    required this.onTap,
    this.icon,
    this.isPrimary = false,
  });
}

/// Service degradation widget for graceful handling of service failures
class ServiceDegradationWidget extends StatelessWidget {
  final String serviceName;
  final String message;
  final List<String> availableFeatures;
  final List<String> unavailableFeatures;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool isExpanded;

  const ServiceDegradationWidget({
    super.key,
    required this.serviceName,
    required this.message,
    this.availableFeatures = const [],
    this.unavailableFeatures = const [],
    this.onRetry,
    this.onDismiss,
    this.isExpanded = false,
  });

  factory ServiceDegradationWidget.aiServiceDown({
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return ServiceDegradationWidget(
      serviceName: 'AI Analysis',
      message: 'AI-powered insights are temporarily unavailable. You can still create and save journal entries.',
      availableFeatures: [
        'Create journal entries',
        'Save entries locally',
        'View existing entries',
        'Export data',
      ],
      unavailableFeatures: [
        'AI emotional analysis',
        'Insight generation',
        'Sentiment tracking',
        'Pattern recognition',
      ],
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }

  factory ServiceDegradationWidget.syncServiceDown({
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return ServiceDegradationWidget(
      serviceName: 'Sync Service',
      message: 'Data synchronization is temporarily unavailable. Your entries are saved locally.',
      availableFeatures: [
        'Create and edit entries',
        'Local data storage',
        'Offline functionality',
        'Export capabilities',
      ],
      unavailableFeatures: [
        'Cross-device sync',
        'Cloud backup',
        'Real-time updates',
        'Remote data access',
      ],
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      color: theme.colorScheme.warningContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  color: theme.colorScheme.onWarningContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$serviceName Service Issue',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onWarningContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close),
                    color: theme.colorScheme.onWarningContainer,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onWarningContainer,
              ),
            ),
            if (isExpanded && (availableFeatures.isNotEmpty || unavailableFeatures.isNotEmpty)) ...[
              const SizedBox(height: 16),
              _buildFeaturesList(context),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onRetry != null) ...[
                  RetryButton(
                    onRetry: onRetry,
                    text: 'Retry Service',
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Continuing with available features'),
                      ),
                    );
                  },
                  child: const Text('Continue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (availableFeatures.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                'Available Features:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onWarningContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...availableFeatures.map((feature) => Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 2),
                child: Text(
                  '• $feature',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onWarningContainer,
                  ),
                ),
              )),
          const SizedBox(height: 8),
        ],
        if (unavailableFeatures.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.cancel_outlined,
                size: 16,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                'Temporarily Unavailable:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onWarningContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...unavailableFeatures.map((feature) => Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 2),
                child: Text(
                  '• $feature',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onWarningContainer,
                  ),
                ),
              )),
        ],
      ],
    );
  }
}

/// Enhanced error boundary widget that catches and handles widget errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;
  final void Function(Object error, StackTrace? stackTrace)? onError;
  final String? fallbackMessage;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
    this.fallbackMessage,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }
      
      return EmptyStateWidget(
        title: 'Something went wrong',
        message: widget.fallbackMessage ?? 'An error occurred while loading this content.',
        icon: Icons.error_outline,
        actions: [
          EmptyStateAction(
            label: 'Try Again',
            onTap: () {
              setState(() {
                _error = null;
                _stackTrace = null;
              });
            },
            isPrimary: true,
            icon: Icons.refresh,
          ),
        ],
      );
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ErrorWidget.builder = (FlutterErrorDetails details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _error = details.exception;
            _stackTrace = details.stack;
          });
          widget.onError?.call(details.exception, details.stack);
        }
      });
      return const SizedBox.shrink();
    };
  }
}

// Extension to Theme for warning colors (since it's not in standard ColorScheme)
extension ThemeExtension on ColorScheme {
  Color get warningContainer => const Color(0xFFFFF8E1);
  Color get onWarningContainer => const Color(0xFF8A6914);
}