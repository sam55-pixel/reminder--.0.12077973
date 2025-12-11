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
      locationKey: fields[1] as dynamic,
      triggerType: fields[2] as String,
      scheduledTime: fields[3] as DateTime?,
      created: fields[4] as DateTime,
      active: fields[5] as bool,
      triggerMode: fields[6] as String,
      ignoredContexts: (fields[7] as Map?)?.cast<String, int>(),
      permanentlyBlockedIn: (fields[8] as List?)?.cast<String>(),
      wasNotified: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.locationKey)
      ..writeByte(2)
      ..write(obj.triggerType)
      ..writeByte(3)
      ..write(obj.scheduledTime)
      ..writeByte(4)
      ..write(obj.created)
      ..writeByte(5)
      ..write(obj.active)
      ..writeByte(6)
      ..write(obj.triggerMode)
      ..writeByte(7)
      ..write(obj.ignoredContexts)
      ..writeByte(8)
      ..write(obj.permanentlyBlockedIn)
      ..writeByte(9)
      ..write(obj.wasNotified);
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
