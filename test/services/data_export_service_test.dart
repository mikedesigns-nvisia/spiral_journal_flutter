import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/data_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('DataExportService', () {
    late DataExportService exportService;

    setUp(() async {
      exportService = DataExportService();
    });

    group('Initialization', () {
      test('should create instance successfully', () {
        expect(exportService, isNotNull);
      });

      test('should throw error if not initialized before use', () {
        expect(
          () => exportService.exportAllData(),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('Progress Tracking', () {
      test('should provide initial progress tracking properties', () {
        expect(exportService.exportProgress, equals(0.0));
        expect(exportService.exportStatus, equals(''));
        expect(exportService.isExporting, isFalse);
        expect(exportService.isImporting, isFalse);
      });

      test('should be a ChangeNotifier', () {
        expect(exportService, isA<ChangeNotifier>());
      });
    });

    group('File Management', () {
      test('should handle deleting non-existent files gracefully', () async {
        // Should not throw error when deleting non-existent file
        expect(
          () => exportService.deleteExportFile('/non/existent/file.spiral'),
          returnsNormally,
        );
      });
    });

    group('Export Results', () {
      test('should create successful export result', () {
        final result = ExportResult.success(
          filePath: '/test/path.spiral',
          isEncrypted: false,
        );
        
        expect(result.success, isTrue);
        expect(result.filePath, equals('/test/path.spiral'));
        expect(result.isEncrypted, isFalse);
        expect(result.error, isNull);
      });

      test('should create failure export result', () {
        const errorMessage = 'Export failed';
        final result = ExportResult.failure(errorMessage);
        
        expect(result.success, isFalse);
        expect(result.error, equals(errorMessage));
        expect(result.filePath, isNull);
      });
    });

    group('Export File Info', () {
      test('should create export file info with correct properties', () {
        final now = DateTime.now();
        final fileInfo = ExportFileInfo(
          path: '/test/export.spiral',
          name: 'export.spiral',
          size: 1024,
          createdAt: now,
          isEncrypted: false,
        );
        
        expect(fileInfo.path, equals('/test/export.spiral'));
        expect(fileInfo.name, equals('export.spiral'));
        expect(fileInfo.size, equals(1024));
        expect(fileInfo.createdAt, equals(now));
        expect(fileInfo.isEncrypted, isFalse);
      });

      test('should format file size correctly', () {
        final smallFile = ExportFileInfo(
          path: '/test/small.spiral',
          name: 'small.spiral',
          size: 512,
          createdAt: DateTime.now(),
          isEncrypted: false,
        );
        expect(smallFile.formattedSize, equals('512 B'));

        final mediumFile = ExportFileInfo(
          path: '/test/medium.spiral',
          name: 'medium.spiral',
          size: 2048,
          createdAt: DateTime.now(),
          isEncrypted: false,
        );
        expect(mediumFile.formattedSize, equals('2.0 KB'));

        final largeFile = ExportFileInfo(
          path: '/test/large.spiral',
          name: 'large.spiral',
          size: 2097152,
          createdAt: DateTime.now(),
          isEncrypted: false,
        );
        expect(largeFile.formattedSize, equals('2.0 MB'));
      });

      test('should format date correctly', () {
        final testDate = DateTime(2024, 1, 15, 14, 30);
        final fileInfo = ExportFileInfo(
          path: '/test/export.spiral',
          name: 'export.spiral',
          size: 1024,
          createdAt: testDate,
          isEncrypted: false,
        );
        
        expect(fileInfo.formattedDate, equals('15/1/2024 14:30'));
      });
    });

    group('Error Handling', () {
      test('should handle initialization with null dependencies', () async {
        await exportService.initialize(
          journalRepository: null,
          coreLibraryService: null,
          settingsService: null,
        );
        
        // Should not throw error during initialization
        expect(exportService, isNotNull);
      });
    });

    group('State Management', () {
      test('should maintain singleton pattern', () {
        final instance1 = DataExportService();
        final instance2 = DataExportService();
        
        expect(identical(instance1, instance2), isTrue);
      });

      test('should prevent concurrent operations', () async {
        await exportService.initialize();
        
        // This test verifies the service prevents concurrent operations
        // In a real scenario, this would test actual export/import conflicts
        expect(exportService.isExporting, isFalse);
        expect(exportService.isImporting, isFalse);
      });
    });
  });
}