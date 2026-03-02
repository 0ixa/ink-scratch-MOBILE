// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_history_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReadingHistoryHiveModelAdapter
    extends TypeAdapter<ReadingHistoryHiveModel> {
  @override
  final int typeId = 5;

  @override
  ReadingHistoryHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadingHistoryHiveModel(
      id: fields[0] as String,
      mangaId: fields[1] as String,
      title: fields[2] as String,
      author: fields[3] as String,
      coverImage: fields[4] as String?,
      chapterNumber: fields[5] as int?,
      chapterTitle: fields[6] as String?,
      progress: fields[7] as double,
      lastReadAt: fields[8] as DateTime?,
      createdAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ReadingHistoryHiveModel obj) {
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
      ..write(obj.chapterNumber)
      ..writeByte(6)
      ..write(obj.chapterTitle)
      ..writeByte(7)
      ..write(obj.progress)
      ..writeByte(8)
      ..write(obj.lastReadAt)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingHistoryHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
