// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'o_auth_login_request_provider.dart';

part 'o_auth_login_request.freezed.dart';
part 'o_auth_login_request.g.dart';

/// OAuth login request.
@Freezed()
abstract class OAuthLoginRequest with _$OAuthLoginRequest {
  const factory OAuthLoginRequest({
    required OAuthLoginRequestProvider provider,
    @JsonKey(name: 'access_token')
    required String accessToken,
    required String email,
    String? name,
  }) = _OAuthLoginRequest;
  
  factory OAuthLoginRequest.fromJson(Map<String, Object?> json) => _$OAuthLoginRequestFromJson(json);
}
