// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_validation_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HttpValidationError _$HttpValidationErrorFromJson(Map<String, dynamic> json) =>
    _HttpValidationError(
      detail: (json['detail'] as List<dynamic>?)
          ?.map((e) => ValidationError.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$HttpValidationErrorToJson(
  _HttpValidationError instance,
) => <String, dynamic>{'detail': instance.detail};
