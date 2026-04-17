// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'validation_error.freezed.dart';
part 'validation_error.g.dart';

@Freezed()
abstract class ValidationError with _$ValidationError {
  const factory ValidationError({
    required List<dynamic> loc,
    required String msg,
    required String type,
  }) = _ValidationError;

  factory ValidationError.fromJson(Map<String, Object?> json) =>
      _$ValidationErrorFromJson(json);
}
