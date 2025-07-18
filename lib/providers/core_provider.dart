import 'package:flutter/foundation.dart';
import '../models/core.dart';
import '../services/journal_service.dart';

class CoreProvider with ChangeNotifier {
  final JournalService _journalService = JournalService();
  
  List<EmotionalCore> _allCores = [];
  List<EmotionalCore> _topCores = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<EmotionalCore> get allCores => _allCores;
  List<EmotionalCore> get topCores => _topCores;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get cores by trend
  List<EmotionalCore> getCoresByTrend(String trend) {
    return _allCores.where((core) => core.trend == trend).toList();
  }

  // Get rising cores
  List<EmotionalCore> get risingCores => getCoresByTrend('rising');

  // Get declining cores  
  List<EmotionalCore> get decliningCores => getCoresByTrend('declining');

  // Get stable cores
  List<EmotionalCore> get stableCores => getCoresByTrend('stable');

  // Initialize cores
  Future<void> initialize() async {
    await loadAllCores();
    await loadTopCores();
  }

  // Load all emotional cores
  Future<void> loadAllCores() async {
    try {
      _setLoading(true);
      _error = null;
      
      final cores = await _journalService.getAllCores();
      _allCores = cores;
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Load top cores (for dashboard display)
  Future<void> loadTopCores({int limit = 3}) async {
    try {
      _setLoading(true);
      _error = null;
      
      final cores = await _journalService.getTopCores(limit);
      _topCores = cores;
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Update a core (usually called after AI analysis)
  Future<bool> updateCore(EmotionalCore core) async {
    try {
      _setLoading(true);
      _error = null;
      
      await _journalService.updateCore(core);
      
      // Update local lists
      final allIndex = _allCores.indexWhere((c) => c.id == core.id);
      if (allIndex != -1) {
        _allCores[allIndex] = core;
      }
      
      final topIndex = _topCores.indexWhere((c) => c.id == core.id);
      if (topIndex != -1) {
        _topCores[topIndex] = core;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get core by name
  EmotionalCore? getCoreByName(String name) {
    try {
      return _allCores.firstWhere(
        (core) => core.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Get core by ID
  EmotionalCore? getCoreById(String id) {
    try {
      return _allCores.firstWhere((core) => core.id == id);
    } catch (e) {
      return null;
    }
  }

  // Refresh all core data
  Future<void> refresh() async {
    await loadAllCores();
    await loadTopCores();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}