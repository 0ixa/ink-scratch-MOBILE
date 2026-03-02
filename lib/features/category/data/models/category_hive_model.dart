// lib/features/category/data/models/category_hive_model.dart

import 'package:hive_ce/hive.dart'; // ✅ was: package:hive/hive.dart

part 'category_hive_model.g.dart';

@HiveType(typeId: 1)
class CategoryHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int color;

  @HiveField(3)
  final DateTime createdAt;

  CategoryHiveModel({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  factory CategoryHiveModel.create({
    required String id,
    required String name,
    required int color,
  }) {
    return CategoryHiveModel(
      id: id,
      name: name,
      color: color,
      createdAt: DateTime.now(),
    );
  }
}
