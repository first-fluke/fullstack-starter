// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_exchange_request.freezed.dart';
part 'session_exchange_request.g.dart';

/// Exchange better-auth session token for backend JWE tokens.
@Freezed()
abstract class SessionExchangeRequest with _$SessionExchangeRequest {
  const factory SessionExchangeRequest({
    @JsonKey(name: 'session_token')
    required String sessionToken,
  }) = _SessionExchangeRequest;
  
  factory SessionExchangeRequest.fromJson(Map<String, Object?> json) => _$SessionExchangeRequestFromJson(json);
}
