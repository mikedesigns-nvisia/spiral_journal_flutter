import 'package:flutter/material.dart';
import '../design_system/design_tokens.dart';
import '../design_system/component_library.dart';
import '../utils/app_error_handler.dart';

/// Widget for displaying user-friendly error messages with retry options
class ErrorDisplayWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showDetails;

  const ErrorDisplayWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = _getErrorColor(context);

    return ComponentLibrary.card(
      margin: ComponentTokens.errorDisplayMargin,
      padding: ComponentTokens.errorDisplayPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getErrorIcon(),
                color: errorColor,
                size: ComponentTokens.errorIconSize,
              ),
              const SizedBox(width: ComponentTokens.errorIconSpacing),
              Expanded(
                child: Text(
                  _getErrorTitle(),
                  style: DesignTokens.getTextStyle(
                    fontSize: DesignTokens.fontSizeL,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: errorColor,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close),
                  iconSize: DesignTokens.iconSizeM,
                ),
            ],
          ),
          const SizedBox(height: ComponentTokens.errorContentSpacing),
          Text(
            error.userMessage,
            style: DesignTokens.getTextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightRegular,
              color: DesignTokens.getTextPrimary(context),
            ),
          ),
          if (showDetails && error.operationName != null) ...[
            const SizedBox(height: ComponentTokens.errorContentSpacing),
            Text(
              'Operation: ${error.operationName}',
              style: DesignTokens.getTextStyle(
                fontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightRegular,
                color: DesignTokens.getTextTertiary(context),
              ),
            ),
          ],
          const SizedBox(height: ComponentTokens.errorActionsSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (error.isRecoverable && onRetry != null) ...[
                ComponentLibrary.textButton(
                  text: 'Try Again',
                  onPressed: onRetry,
                  icon: Icons.refresh,
                  size: ButtonSize.small,
                ),
                const SizedBox(width: ComponentTokens.errorActionSpacing),
              ],
              ComponentLibrary.textButton(
                text: 'OK',
                onPressed: onDismiss ?? () {},
                size: ButtonSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (error.category) {
      case ErrorCategory.connectivity:
        return Icons.wifi_off;
      case ErrorCategory.storage:
        return Icons.storage;
      case ErrorCategory.security:
        return Icons.security;
      case ErrorCategory.data:
        return Icons.data_usage;
      case ErrorCategory.system:
        return Icons.error_outline;
      default:
        return Icons.warning;
    }
  }

  Color _getErrorColor(BuildContext context) {
    switch (error.category) {
      case ErrorCategory.connectivity:
        return DesignTokens.infoColor;
      case ErrorCategory.security:
        return DesignTokens.errorColor;
      case ErrorCategory.storage:
        return DesignTokens.warningColor;
      case ErrorCategory.data:
        return DesignTokens.errorColor;
      case ErrorCategory.system:
        return DesignTokens.errorColor;
      default:
        return DesignTokens.errorColor;
    }
  }

  String _getErrorTitle() {
    switch (error.category) {
      case ErrorCategory.connectivity:
        return 'Connection Issue';
      case ErrorCategory.storage:
        return 'Storage Error';
      case ErrorCategory.security:
        return 'Security Error';
      case ErrorCategory.data:
        return 'Data Error';
      case ErrorCategory.system:
        return 'System Error';
      default:
        return 'Error';
    }
  }
}

/// Snackbar for showing quick error messages
class ErrorSnackBar {
  static void show(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getErrorIcon(error.category),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.userMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _getErrorColor(error.category, context),
        action: error.isRecoverable && onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static IconData _getErrorIcon(ErrorCategory category) {
    switch (category) {
      case ErrorCategory.connectivity:
        return Icons.wifi_off;
      case ErrorCategory.storage:
        return Icons.storage;
      case ErrorCategory.security:
        return Icons.security;
      case ErrorCategory.data:
        return Icons.data_usage;
      case ErrorCategory.system:
        return Icons.error_outline;
      default:
        return Icons.warning;
    }
  }

  static Color _getErrorColor(ErrorCategory category, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (category) {
      case ErrorCategory.connectivity:
        return Colors.orange;
      case ErrorCategory.security:
        return colorScheme.error;
      case ErrorCategory.storage:
        return Colors.blue;
      default:
        return Colors.red;
    }
  }
}

/// Dialog for showing detailed error information
class ErrorDialog extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
  });

  static Future<void> show(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        error: error,
        onRetry: onRetry,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      icon: Icon(
        _getErrorIcon(),
        color: theme.colorScheme.error,
        size: 32,
      ),
      title: Text(_getErrorTitle()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error.userMessage),
          if (error.operationName != null) ...[
            const SizedBox(height: 16),
            Text(
              'Details:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Operation: ${error.operationName}',
              style: theme.textTheme.bodySmall,
            ),
            if (error.component != null)
              Text(
                'Component: ${error.component}',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ],
      ),
      actions: [
        if (error.isRecoverable && onRetry != null)
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  IconData _getErrorIcon() {
    switch (error.category) {
      case ErrorCategory.connectivity:
        return Icons.wifi_off;
      case ErrorCategory.storage:
        return Icons.storage;
      case ErrorCategory.security:
        return Icons.security;
      case ErrorCategory.data:
        return Icons.data_usage;
      case ErrorCategory.system:
        return Icons.error_outline;
      default:
        return Icons.warning;
    }
  }

  String _getErrorTitle() {
    switch (error.category) {
      case ErrorCategory.connectivity:
        return 'Connection Issue';
      case ErrorCategory.storage:
        return 'Storage Error';
      case ErrorCategory.security:
        return 'Security Error';
      case ErrorCategory.data:
        return 'Data Error';
      case ErrorCategory.system:
        return 'System Error';
      default:
        return 'Error';
    }
  }
}
