// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import 'o_auth_login_request_provider.dart';

part 'api_auth_login_request_body_union.freezed.dart';
part 'api_auth_login_request_body_union.g.dart';

@Freezed()
sealed class ApiAuthLoginRequestBodyUnion with _$ApiAuthLoginRequestBodyUnion {
  @JsonSerializable()
  const factory ApiAuthLoginRequestBodyUnion.oAuthLoginRequest({
    required OAuthLoginRequestProvider provider,
    @JsonKey(name: 'access_token') required String accessToken,
    required String email,
    String? name,
  }) = ApiAuthLoginRequestBodyUnionOAuthLoginRequest;

  @JsonSerializable()
  const factory ApiAuthLoginRequestBodyUnion.emailLoginRequest({
    required String email,
    required String password,
  }) = ApiAuthLoginRequestBodyUnionEmailLoginRequest;

  factory ApiAuthLoginRequestBodyUnion.fromJson(Map<String, Object?> json) =>
      // TODO: No discriminator in OpenAPI spec - you must implement this manually.
      //
      // Inspect the JSON and return the matching variant. Each variant has a fromJson:
      //   ApiAuthLoginRequestBodyUnionVariantName.fromJson(json)
      //
      // Example pattern (check for unique fields):
      //   json.containsKey('uniqueFieldA') ? ApiAuthLoginRequestBodyUnionTypeA.fromJson(json) :
      //   json.containsKey('uniqueFieldB') ? ApiAuthLoginRequestBodyUnionTypeB.fromJson(json) :
      //   ApiAuthLoginRequestBodyUnionDefault.fromJson(json);
      //
      // IMPORTANT: Keep the => arrow syntax. Converting to a { } body will cause
      // freezed to skip generating toJson/fromJson for this class.
      throw UnimplementedError();
}
