// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_account_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuthAccountModelAdapter extends TypeAdapter<AuthAccountModel> {
  @override
  final typeId = 1;

  @override
  AuthAccountModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuthAccountModel(
      name: fields[0] as String,
      salt: fields[1] as String,
      passwordHash: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AuthAccountModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.salt)
      ..writeByte(2)
      ..write(obj.passwordHash);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthAccountModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
