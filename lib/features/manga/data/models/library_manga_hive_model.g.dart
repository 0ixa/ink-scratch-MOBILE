// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_manga_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LibraryMangaHiveModelAdapter extends TypeAdapter<LibraryMangaHiveModel> {
  @override
  final typeId = 1;

  @override
  LibraryMangaHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LibraryMangaHiveModel(
      id: fields[0] as String,
      mangaId: fields[1] as String,
      title: fields[2] as String,
      author: fields[3] as String,
      coverImage: fields[4] as String?,
      status: fields[5] as String,
      rating: (fields[6] as num).toDouble(),
      genre: (fields[7] as List).cast<String>(),
      addedAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LibraryMangaHiveModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.mangaId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.author)
      ..writeByte(4)
      ..write(obj.coverImage)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.rating)
      ..writeByte(7)
      ..write(obj.genre)
      ..writeByte(8)
      ..write(obj.addedAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryMangaHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
