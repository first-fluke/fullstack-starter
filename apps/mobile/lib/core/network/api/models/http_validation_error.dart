// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'validation_error.dart';

part 'http_validation_error.freezed.dart';
part 'http_validation_error.g.dart';

@Freezed()
abstract class HttpValidationError with _$HttpValidationError {
  const factory HttpValidationError({
    List<ValidationError>? detail,
  }) = _HttpValidationError;

  factory HttpValidationError.fromJson(Map<String, Object?> json) =>
      _$HttpValidationErrorFromJson(json);
}
