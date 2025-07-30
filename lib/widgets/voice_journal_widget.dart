import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/voice_journal_service.dart';
import '../theme/app_theme.dart';
import '../design_system/heading_system.dart';

/// Widget for voice-to-text journal entry input
class VoiceJournalWidget extends StatefulWidget {
  final Function(String) onTranscriptionComplete;
  final Function(String)? onTranscriptionUpdate;
  final VoidCallback? onPermissionDenied;
  final bool enabled;
  final String? initialText;

  const VoiceJournalWidget({
    super.key,
    required this.onTranscriptionComplete,
    this.onTranscriptionUpdate,
    this.onPermissionDenied,
    this.enabled = true,
    this.initialText,
  });

  @override
  State<VoiceJournalWidget> createState() => _VoiceJournalWidgetState();
}

class _VoiceJournalWidgetState extends State<VoiceJournalWidget>
    with TickerProviderStateMixin {
  late VoiceJournalService _voiceService;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  
  StreamSubscription<String>? _transcriptionSubscription;
  StreamSubscription<VoiceJournalStatus>? _statusSubscription;
  StreamSubscription<double>? _soundLevelSubscription;
  
  VoiceJournalStatus _currentStatus = VoiceJournalStatus.idle;
  String _currentTranscription = '';
  double _soundLevel = 0.0;
  String? _errorMessage;
  bool _isInitialized = false;
  bool _supportsOffline = false;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceJournalService();
    _setupAnimations();
    _initializeVoiceService();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeVoiceService() async {
    try {
      debugPrint('🎤 Initializing voice journal widget...');
      
      final result = await _voiceService.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = result.success;
          _supportsOffline = result.supportsOffline;
          if (!result.success) {
            _errorMessage = result.error;
            _currentStatus = VoiceJournalStatus.error;
          }
        });
      }

      if (result.success) {
        _setupStreamListeners();
        debugPrint('✅ Voice journal widget initialized');
        debugPrint('🔒 Offline support: $_supportsOffline');
      } else {
        debugPrint('❌ Failed to initialize voice journal: ${result.error}');
      }
    } catch (e) {
      debugPrint('❌ Exception during voice service initialization: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize voice recognition: ${e.toString()}';
          _currentStatus = VoiceJournalStatus.error;
        });
      }
    }
  }

  void _setupStreamListeners() {
    _transcriptionSubscription = _voiceService.transcriptionStream.listen(
      (transcription) {
        if (mounted) {
          setState(() {
            _currentTranscription = transcription;
          });
          widget.onTranscriptionUpdate?.call(transcription);
        }
      },
    );

    _statusSubscription = _voiceService.statusStream.listen(
      (status) {
        if (mounted) {
          setState(() {
            _currentStatus = status;
            if (status == VoiceJournalStatus.error) {
              _stopAnimations();
            }
          });
          _handleStatusChange(status);
        }
      },
    );

    _soundLevelSubscription = _voiceService.soundLevelStream.listen(
      (level) {
        if (mounted) {
          setState(() {
            _soundLevel = level;
          });
        }
      },
    );
  }

  void _handleStatusChange(VoiceJournalStatus status) {
    switch (status) {
      case VoiceJournalStatus.listening:
        _startListeningAnimations();
        HapticFeedback.lightImpact();
        break;
      case VoiceJournalStatus.processing:
        // Continue animations during processing
        break;
      case VoiceJournalStatus.completed:
        _stopAnimations();
        widget.onTranscriptionComplete(_currentTranscription);
        HapticFeedback.mediumImpact();
        break;
      case VoiceJournalStatus.stopped:
        _stopAnimations();
        if (_currentTranscription.trim().isNotEmpty) {
          widget.onTranscriptionComplete(_currentTranscription);
        }
        break;
      case VoiceJournalStatus.cancelled:
        _stopAnimations();
        break;
      case VoiceJournalStatus.interrupted:
        _stopAnimations();
        HapticFeedback.mediumImpact();
        break;
      case VoiceJournalStatus.resuming:
        // Show UI indication that recording can be resumed
        break;
      case VoiceJournalStatus.error:
        _stopAnimations();
        HapticFeedback.heavyImpact();
        break;
      default:
        break;
    }
  }

  void _startListeningAnimations() {
    _pulseController.repeat(reverse: true);
    _waveController.repeat(reverse: true);
  }

  void _stopAnimations() {
    _pulseController.stop();
    _waveController.stop();
    _pulseController.reset();
    _waveController.reset();
  }

  Future<void> _toggleListening() async {
    if (!_isInitialized) {
      _showErrorSnackBar('Voice recognition not initialized');
      return;
    }

    if (!widget.enabled) {
      return;
    }

    try {
      if (_voiceService.isListening) {
        // Stop listening
        debugPrint('🛑 Stopping voice recognition...');
        final result = await _voiceService.stopListening();
        
        if (!result.success && result.error != null) {
          _showErrorSnackBar(result.error!);
        }
      } else {
        // Start listening
        debugPrint('🎤 Starting voice recognition...');
        setState(() {
          _currentTranscription = '';
          _errorMessage = null;
        });

        final result = await _voiceService.startListening(
          preferOffline: true,
          timeout: const Duration(minutes: 5),
        );

        if (!result.success) {
          if (result.errorType == VoiceJournalErrorType.permissionDenied) {
            widget.onPermissionDenied?.call();
            _showPermissionDialog(result.needsSettingsRedirect);
          } else {
            _showErrorSnackBar(result.error ?? 'Failed to start voice recognition');
          }
        } else {
          debugPrint('✅ Voice recognition started');
          debugPrint('🔒 Using offline mode: ${result.isUsingOfflineMode}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error toggling voice recognition: $e');
      _showErrorSnackBar('Voice recognition error: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppTheme.accentRed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showPermissionDialog(bool needsSettingsRedirect) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.mic_off, color: AppTheme.accentRed),
            const SizedBox(width: 12),
            const Text('Microphone Permission'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spiral Journal needs microphone permission to convert your voice to text for journal entries.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: AppTheme.getPrimaryColor(context),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'All speech processing happens on your device for privacy.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (needsSettingsRedirect) {
                await _voiceService.openPermissionSettings();
              } else {
                await _voiceService.requestMicrophonePermission();
              }
            },
            child: Text(needsSettingsRedirect ? 'Open Settings' : 'Grant Permission'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _transcriptionSubscription?.cancel();
    _statusSubscription?.cancel();
    _soundLevelSubscription?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundSecondary(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status and offline indicator
          _buildStatusRow(),
          
          const SizedBox(height: 16),
          
          // Voice button with animation
          _buildVoiceButton(),
          
          const SizedBox(height: 16),
          
          // Transcription display
          if (_currentTranscription.isNotEmpty) _buildTranscriptionDisplay(),
          
          // Error message
          if (_errorMessage != null) _buildErrorDisplay(),
          
          // Instructions
          if (_currentTranscription.isEmpty && _errorMessage == null)
            _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    return Row(
      children: [
        Icon(
          _getStatusIcon(),
          color: _getStatusColor(),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          _getStatusText(),
          style: HeadingSystem.getLabelMedium(context).copyWith(
            color: _getStatusColor(),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (_supportsOffline) ...[
          Icon(
            Icons.offline_bolt,
            color: AppTheme.accentGreen,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'On-Device',
            style: HeadingSystem.getLabelSmall(context).copyWith(
              color: AppTheme.accentGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVoiceButton() {
    return GestureDetector(
      onTap: widget.enabled ? _toggleListening : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _waveAnimation]),
        builder: (context, child) {
          final isListening = _currentStatus == VoiceJournalStatus.listening;
          final scale = isListening ? _pulseAnimation.value : 1.0;
          
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getButtonColor(),
                boxShadow: [
                  BoxShadow(
                    color: _getButtonColor().withOpacity(0.4),
                    blurRadius: isListening ? 20 : 8,
                    spreadRadius: isListening ? 4 : 0,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Wave animation
                  if (isListening)
                    Opacity(
                      opacity: _waveAnimation.value * 0.3,
                      child: Container(
                        width: 80 + (_waveAnimation.value * 20),
                        height: 80 + (_waveAnimation.value * 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getButtonColor(),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  
                  // Microphone icon
                  Icon(
                    _getButtonIcon(),
                    color: Colors.white,
                    size: 32,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTranscriptionDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundPrimary(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.transcription,
                color: AppTheme.getPrimaryColor(context),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Transcription',
                style: HeadingSystem.getLabelMedium(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentTranscription,
            style: HeadingSystem.getBodyMedium(context),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentRed.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.accentRed,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: HeadingSystem.getBodySmall(context).copyWith(
                color: AppTheme.accentRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Text(
      'Tap the microphone to start voice recording. Speak clearly for best results.',
      style: HeadingSystem.getBodySmall(context).copyWith(
        color: AppTheme.getTextSecondary(context),
      ),
      textAlign: TextAlign.center,
    );
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case VoiceJournalStatus.listening:
        return AppTheme.accentGreen;
      case VoiceJournalStatus.processing:
        return AppTheme.getPrimaryColor(context);
      case VoiceJournalStatus.completed:
        return AppTheme.accentGreen;
      case VoiceJournalStatus.interrupted:
        return AppTheme.accentYellow;
      case VoiceJournalStatus.resuming:
        return AppTheme.getPrimaryColor(context);
      case VoiceJournalStatus.error:
        return AppTheme.accentRed;
      default:
        return AppTheme.getTextSecondary(context);
    }
  }

  IconData _getStatusIcon() {
    switch (_currentStatus) {
      case VoiceJournalStatus.listening:
        return Icons.mic;
      case VoiceJournalStatus.processing:
        return Icons.sync;
      case VoiceJournalStatus.completed:
        return Icons.check_circle;
      case VoiceJournalStatus.interrupted:
        return Icons.pause_circle;
      case VoiceJournalStatus.resuming:
        return Icons.play_circle;
      case VoiceJournalStatus.error:
        return Icons.error;
      default:
        return Icons.mic_none;
    }
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case VoiceJournalStatus.listening:
        return 'Listening...';
      case VoiceJournalStatus.processing:
        return 'Processing...';
      case VoiceJournalStatus.completed:
        return 'Complete';
      case VoiceJournalStatus.stopped:
        return 'Stopped';
      case VoiceJournalStatus.cancelled:
        return 'Cancelled';
      case VoiceJournalStatus.interrupted:
        return 'Interrupted';
      case VoiceJournalStatus.resuming:
        return 'Ready to Resume';
      case VoiceJournalStatus.error:
        return 'Error';
      default:
        return 'Ready';
    }
  }

  Color _getButtonColor() {
    if (!widget.enabled) {
      return AppTheme.getTextSecondary(context);
    }
    
    switch (_currentStatus) {
      case VoiceJournalStatus.listening:
        return AppTheme.accentRed;
      case VoiceJournalStatus.processing:
        return AppTheme.getPrimaryColor(context);
      default:
        return AppTheme.getPrimaryColor(context);
    }
  }

  IconData _getButtonIcon() {
    switch (_currentStatus) {
      case VoiceJournalStatus.listening:
        return Icons.stop;
      case VoiceJournalStatus.processing:
        return Icons.sync;
      default:
        return Icons.mic;
    }
  }
}