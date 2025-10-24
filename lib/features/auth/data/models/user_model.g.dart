// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      scannerId: json['scannerId'] as String,
      vendorId: json['vendorId'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      username: json['username'] as String,
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'role': instance.role,
      'scannerId': instance.scannerId,
      'vendorId': instance.vendorId,
      'phoneNumber': instance.phoneNumber,
      'username': instance.username,
      'isActive': instance.isActive,
    };
