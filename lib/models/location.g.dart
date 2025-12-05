// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StoredLocationAdapter extends TypeAdapter<StoredLocation> {
  @override
  final int typeId = 1;

  @override
  StoredLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoredLocation(
      name: fields[0] as String,
      lat: fields[1] as double,
      lng: fields[2] as double,
      savedOn: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, StoredLocation obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.lat)
      ..writeByte(2)
      ..write(obj.lng)
      ..writeByte(3)
      ..write(obj.savedOn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoredLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
