// test/features/catagory/presentation/viewmodel/category_viewmodel_test.dart
//
// CategoryViewModel uses HiveService directly as a private singleton field,
// so it cannot be injected or mocked without initialising Hive.
// These tests therefore cover:
//   • CategoryState  (5 pure-Dart tests)
//   • CategoryEntity (5 pure-Dart tests)
// Both are entirely Hive-free.

import 'package:flutter_test/flutter_test.dart';

import 'package:ink_scratch/features/category/domain/entities/category_entity.dart';
import 'package:ink_scratch/features/category/presentation/state/category_state.dart';

// ── Fixture ───────────────────────────────────────────────────────────────────

CategoryEntity _entity(String id, String name) => CategoryEntity(
  id: id,
  name: name,
  color: 0xFF0000FF,
  createdAt: DateTime(2024, 1, 1),
);

// ══════════════════════════════════════════════════════════════════════════════
void main() {
  // ── CategoryState — 5 tests ───────────────────────────────────────────────
  group('CategoryState', () {
    test('1. initial() has isLoading=false and empty categories', () {
      final s = CategoryState.initial();
      expect(s.isLoading, isFalse);
      expect(s.categories, isEmpty);
      expect(s.error, isNull);
    });

    test(
      '2. copyWith(isLoading: true) sets isLoading without touching others',
      () {
        final s = CategoryState.initial().copyWith(isLoading: true);
        expect(s.isLoading, isTrue);
        expect(s.categories, isEmpty);
        expect(s.error, isNull);
      },
    );

    test('3. copyWith replaces categories list correctly', () {
      final s = CategoryState.initial().copyWith(
        categories: [_entity('a', 'Sci-Fi'), _entity('b', 'Horror')],
      );
      expect(s.categories.length, 2);
      expect(s.categories.first.name, 'Sci-Fi');
      expect(s.categories.last.name, 'Horror');
    });

    test('4. copyWith can set an error message', () {
      final s = CategoryState.initial().copyWith(error: 'Load failed');
      expect(s.error, 'Load failed');
    });

    test('5. copyWith with no args preserves all existing values', () {
      final original = CategoryState(
        isLoading: false,
        categories: [_entity('x', 'Action')],
        error: null,
      );
      final copy = original.copyWith();
      expect(copy.isLoading, isFalse);
      expect(copy.categories.length, 1);
      expect(copy.error, isNull);
    });
  });

  // ── CategoryEntity — 5 tests ──────────────────────────────────────────────
  group('CategoryEntity', () {
    test('6. fromMap creates entity with correct fields', () {
      final map = {
        'id': 'cat-1',
        'name': 'Action',
        'description': 'Action manga',
        'color': 0xFFFF0000,
        'createdAt': '2024-06-01T00:00:00.000',
      };
      final entity = CategoryEntity.fromMap(map);
      expect(entity.id, 'cat-1');
      expect(entity.name, 'Action');
      expect(entity.color, 0xFFFF0000);
    });

    test('7. fromMap uses default color when color key is absent', () {
      final map = {
        'id': 'cat-2',
        'name': 'Drama',
        'createdAt': DateTime.now().toIso8601String(),
      };
      final entity = CategoryEntity.fromMap(map);
      expect(entity.color, 0xFF000000);
    });

    test('8. toMap round-trips back through fromMap correctly', () {
      final original = _entity('cat-3', 'Romance');
      final restored = CategoryEntity.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.color, original.color);
    });

    test('9. copyWith returns new entity with updated name only', () {
      final e = _entity('cat-4', 'Fantasy');
      final updated = e.copyWith(name: 'Dark Fantasy');
      expect(updated.name, 'Dark Fantasy');
      expect(updated.id, 'cat-4');
      expect(updated.color, e.color);
      expect(updated.createdAt, e.createdAt);
    });

    test('10. copyWith with no args returns equivalent entity', () {
      final e = _entity('cat-5', 'Thriller');
      final copy = e.copyWith();
      expect(copy.id, e.id);
      expect(copy.name, e.name);
      expect(copy.color, e.color);
      expect(copy.createdAt, e.createdAt);
    });
  });
}
