// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'token_response.freezed.dart';
part 'token_response.g.dart';

/// Token response.
@Freezed()
abstract class TokenResponse with _$TokenResponse {
  const factory TokenResponse({
    @JsonKey(name: 'access_token')
    required String accessToken,
    @JsonKey(name: 'refresh_token')
    required String refreshToken,
    @JsonKey(name: 'token_type')
    @Default('bearer')
    String tokenType,
  }) = _TokenResponse;
  
  factory TokenResponse.fromJson(Map<String, Object?> json) => _$TokenResponseFromJson(json);
}
