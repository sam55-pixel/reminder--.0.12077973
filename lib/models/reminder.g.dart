// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = 0;

  @override
  Reminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reminder(
      title: fields[0] as String,
      locationName: fields[1] as String?,
      lat: fields[2] as double?,
      lng: fields[3] as double?,
      triggerType: fields[4] as String,
      scheduledTime: fields[5] as DateTime?,
      created: fields[6] as DateTime,
      active: fields[7] as bool,
      triggerMode: fields[8] as String,
      ignoredContexts: (fields[9] as Map?)?.cast<String, int>(),
      permanentlyBlockedIn: (fields[10] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.locationName)
      ..writeByte(2)
      ..write(obj.lat)
      ..writeByte(3)
      ..write(obj.lng)
      ..writeByte(4)
      ..write(obj.triggerType)
      ..writeByte(5)
      ..write(obj.scheduledTime)
      ..writeByte(6)
      ..write(obj.created)
      ..writeByte(7)
      ..write(obj.active)
      ..writeByte(8)
      ..write(obj.triggerMode)
      ..writeByte(9)
      ..write(obj.ignoredContexts)
      ..writeByte(10)
      ..write(obj.permanentlyBlockedIn);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
