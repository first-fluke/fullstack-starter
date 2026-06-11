// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_auth_login_request_body_union.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiAuthLoginRequestBodyUnionOAuthLoginRequest
_$ApiAuthLoginRequestBodyUnionOAuthLoginRequestFromJson(
  Map<String, dynamic> json,
) => ApiAuthLoginRequestBodyUnionOAuthLoginRequest(
  provider: OAuthLoginRequestProvider.fromJson(json['provider'] as String),
  accessToken: json['access_token'] as String,
  email: json['email'] as String,
  name: json['name'] as String?,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$ApiAuthLoginRequestBodyUnionOAuthLoginRequestToJson(
  ApiAuthLoginRequestBodyUnionOAuthLoginRequest instance,
) => <String, dynamic>{
  'provider': _$OAuthLoginRequestProviderEnumMap[instance.provider]!,
  'access_token': instance.accessToken,
  'email': instance.email,
  'name': instance.name,
  'runtimeType': instance.$type,
};

const _$OAuthLoginRequestProviderEnumMap = {
  OAuthLoginRequestProvider.google: 'google',
  OAuthLoginRequestProvider.github: 'github',
  OAuthLoginRequestProvider.facebook: 'facebook',
  OAuthLoginRequestProvider.$unknown: r'$unknown',
};

ApiAuthLoginRequestBodyUnionEmailLoginRequest
_$ApiAuthLoginRequestBodyUnionEmailLoginRequestFromJson(
  Map<String, dynamic> json,
) => ApiAuthLoginRequestBodyUnionEmailLoginRequest(
  email: json['email'] as String,
  password: json['password'] as String,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$ApiAuthLoginRequestBodyUnionEmailLoginRequestToJson(
  ApiAuthLoginRequestBodyUnionEmailLoginRequest instance,
) => <String, dynamic>{
  'email': instance.email,
  'password': instance.password,
  'runtimeType': instance.$type,
};
