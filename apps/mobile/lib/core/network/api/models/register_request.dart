// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_request.freezed.dart';
part 'register_request.g.dart';

/// Email/password registration request.
@Freezed()
abstract class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String email,
    required String password,
    String? name,
  }) = _RegisterRequest;
  
  factory RegisterRequest.fromJson(Map<String, Object?> json) => _$RegisterRequestFromJson(json);
}
