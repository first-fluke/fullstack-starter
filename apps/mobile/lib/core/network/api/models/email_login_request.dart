// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'email_login_request.freezed.dart';
part 'email_login_request.g.dart';

/// Email/password login request.
@Freezed()
abstract class EmailLoginRequest with _$EmailLoginRequest {
  const factory EmailLoginRequest({
    required String email,
    required String password,
  }) = _EmailLoginRequest;

  factory EmailLoginRequest.fromJson(Map<String, Object?> json) =>
      _$EmailLoginRequestFromJson(json);
}
