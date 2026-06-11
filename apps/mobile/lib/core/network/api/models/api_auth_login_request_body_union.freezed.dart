// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_auth_login_request_body_union.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
ApiAuthLoginRequestBodyUnion _$ApiAuthLoginRequestBodyUnionFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'oAuthLoginRequest':
          return ApiAuthLoginRequestBodyUnionOAuthLoginRequest.fromJson(
            json
          );
                case 'emailLoginRequest':
          return ApiAuthLoginRequestBodyUnionEmailLoginRequest.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'ApiAuthLoginRequestBodyUnion',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$ApiAuthLoginRequestBodyUnion {

 String get email;
/// Create a copy of ApiAuthLoginRequestBodyUnion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiAuthLoginRequestBodyUnionCopyWith<ApiAuthLoginRequestBodyUnion> get copyWith => _$ApiAuthLoginRequestBodyUnionCopyWithImpl<ApiAuthLoginRequestBodyUnion>(this as ApiAuthLoginRequestBodyUnion, _$identity);

  /// Serializes this ApiAuthLoginRequestBodyUnion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiAuthLoginRequestBodyUnion&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email);

@override
String toString() {
  return 'ApiAuthLoginRequestBodyUnion(email: $email)';
}


}

/// @nodoc
abstract mixin class $ApiAuthLoginRequestBodyUnionCopyWith<$Res>  {
  factory $ApiAuthLoginRequestBodyUnionCopyWith(ApiAuthLoginRequestBodyUnion value, $Res Function(ApiAuthLoginRequestBodyUnion) _then) = _$ApiAuthLoginRequestBodyUnionCopyWithImpl;
@useResult
$Res call({
 String email
});




}
/// @nodoc
class _$ApiAuthLoginRequestBodyUnionCopyWithImpl<$Res>
    implements $ApiAuthLoginRequestBodyUnionCopyWith<$Res> {
  _$ApiAuthLoginRequestBodyUnionCopyWithImpl(this._self, this._then);

  final ApiAuthLoginRequestBodyUnion _self;
  final $Res Function(ApiAuthLoginRequestBodyUnion) _then;

/// Create a copy of ApiAuthLoginRequestBodyUnion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,}) {
  return _then(_self.copyWith(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiAuthLoginRequestBodyUnion].
extension ApiAuthLoginRequestBodyUnionPatterns on ApiAuthLoginRequestBodyUnion {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ApiAuthLoginRequestBodyUnionOAuthLoginRequest value)?  oAuthLoginRequest,TResult Function( ApiAuthLoginRequestBodyUnionEmailLoginRequest value)?  emailLoginRequest,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ApiAuthLoginRequestBodyUnionOAuthLoginRequest() when oAuthLoginRequest != null:
return oAuthLoginRequest(_that);case ApiAuthLoginRequestBodyUnionEmailLoginRequest() when emailLoginRequest != null:
return emailLoginRequest(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ApiAuthLoginRequestBodyUnionOAuthLoginRequest value)  oAuthLoginRequest,required TResult Function( ApiAuthLoginRequestBodyUnionEmailLoginRequest value)  emailLoginRequest,}){
final _that = this;
switch (_that) {
case ApiAuthLoginRequestBodyUnionOAuthLoginRequest():
return oAuthLoginRequest(_that);case ApiAuthLoginRequestBodyUnionEmailLoginRequest():
return emailLoginRequest(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ApiAuthLoginRequestBodyUnionOAuthLoginRequest value)?  oAuthLoginRequest,TResult? Function( ApiAuthLoginRequestBodyUnionEmailLoginRequest value)?  emailLoginRequest,}){
final _that = this;
switch (_that) {
case ApiAuthLoginRequestBodyUnionOAuthLoginRequest() when oAuthLoginRequest != null:
return oAuthLoginRequest(_that);case ApiAuthLoginRequestBodyUnionEmailLoginRequest() when emailLoginRequest != null:
return emailLoginRequest(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( OAuthLoginRequestProvider provider, @JsonKey(name: 'access_token')  String accessToken,  String email,  String? name)?  oAuthLoginRequest,TResult Function( String email,  String password)?  emailLoginRequest,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ApiAuthLoginRequestBodyUnionOAuthLoginRequest() when oAuthLoginRequest != null:
return oAuthLoginRequest(_that.provider,_that.accessToken,_that.email,_that.name);case ApiAuthLoginRequestBodyUnionEmailLoginRequest() when emailLoginRequest != null:
return emailLoginRequest(_that.email,_that.password);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( OAuthLoginRequestProvider provider, @JsonKey(name: 'access_token')  String accessToken,  String email,  String? name)  oAuthLoginRequest,required TResult Function( String email,  String password)  emailLoginRequest,}) {final _that = this;
switch (_that) {
case ApiAuthLoginRequestBodyUnionOAuthLoginRequest():
return oAuthLoginRequest(_that.provider,_that.accessToken,_that.email,_that.name);case ApiAuthLoginRequestBodyUnionEmailLoginRequest():
return emailLoginRequest(_that.email,_that.password);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( OAuthLoginRequestProvider provider, @JsonKey(name: 'access_token')  String accessToken,  String email,  String? name)?  oAuthLoginRequest,TResult? Function( String email,  String password)?  emailLoginRequest,}) {final _that = this;
switch (_that) {
case ApiAuthLoginRequestBodyUnionOAuthLoginRequest() when oAuthLoginRequest != null:
return oAuthLoginRequest(_that.provider,_that.accessToken,_that.email,_that.name);case ApiAuthLoginRequestBodyUnionEmailLoginRequest() when emailLoginRequest != null:
return emailLoginRequest(_that.email,_that.password);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable()
class ApiAuthLoginRequestBodyUnionOAuthLoginRequest implements ApiAuthLoginRequestBodyUnion {
  const ApiAuthLoginRequestBodyUnionOAuthLoginRequest({required this.provider, @JsonKey(name: 'access_token') required this.accessToken, required this.email, this.name, final  String? $type}): $type = $type ?? 'oAuthLoginRequest';
  factory ApiAuthLoginRequestBodyUnionOAuthLoginRequest.fromJson(Map<String, dynamic> json) => _$ApiAuthLoginRequestBodyUnionOAuthLoginRequestFromJson(json);

 final  OAuthLoginRequestProvider provider;
@JsonKey(name: 'access_token') final  String accessToken;
@override final  String email;
 final  String? name;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of ApiAuthLoginRequestBodyUnion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiAuthLoginRequestBodyUnionOAuthLoginRequestCopyWith<ApiAuthLoginRequestBodyUnionOAuthLoginRequest> get copyWith => _$ApiAuthLoginRequestBodyUnionOAuthLoginRequestCopyWithImpl<ApiAuthLoginRequestBodyUnionOAuthLoginRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApiAuthLoginRequestBodyUnionOAuthLoginRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiAuthLoginRequestBodyUnionOAuthLoginRequest&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.email, email) || other.email == email)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,accessToken,email,name);

@override
String toString() {
  return 'ApiAuthLoginRequestBodyUnion.oAuthLoginRequest(provider: $provider, accessToken: $accessToken, email: $email, name: $name)';
}


}

/// @nodoc
abstract mixin class $ApiAuthLoginRequestBodyUnionOAuthLoginRequestCopyWith<$Res> implements $ApiAuthLoginRequestBodyUnionCopyWith<$Res> {
  factory $ApiAuthLoginRequestBodyUnionOAuthLoginRequestCopyWith(ApiAuthLoginRequestBodyUnionOAuthLoginRequest value, $Res Function(ApiAuthLoginRequestBodyUnionOAuthLoginRequest) _then) = _$ApiAuthLoginRequestBodyUnionOAuthLoginRequestCopyWithImpl;
@override @useResult
$Res call({
 OAuthLoginRequestProvider provider,@JsonKey(name: 'access_token') String accessToken, String email, String? name
});




}
/// @nodoc
class _$ApiAuthLoginRequestBodyUnionOAuthLoginRequestCopyWithImpl<$Res>
    implements $ApiAuthLoginRequestBodyUnionOAuthLoginRequestCopyWith<$Res> {
  _$ApiAuthLoginRequestBodyUnionOAuthLoginRequestCopyWithImpl(this._self, this._then);

  final ApiAuthLoginRequestBodyUnionOAuthLoginRequest _self;
  final $Res Function(ApiAuthLoginRequestBodyUnionOAuthLoginRequest) _then;

/// Create a copy of ApiAuthLoginRequestBodyUnion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? accessToken = null,Object? email = null,Object? name = freezed,}) {
  return _then(ApiAuthLoginRequestBodyUnionOAuthLoginRequest(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as OAuthLoginRequestProvider,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc

@JsonSerializable()
class ApiAuthLoginRequestBodyUnionEmailLoginRequest implements ApiAuthLoginRequestBodyUnion {
  const ApiAuthLoginRequestBodyUnionEmailLoginRequest({required this.email, required this.password, final  String? $type}): $type = $type ?? 'emailLoginRequest';
  factory ApiAuthLoginRequestBodyUnionEmailLoginRequest.fromJson(Map<String, dynamic> json) => _$ApiAuthLoginRequestBodyUnionEmailLoginRequestFromJson(json);

@override final  String email;
 final  String password;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of ApiAuthLoginRequestBodyUnion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiAuthLoginRequestBodyUnionEmailLoginRequestCopyWith<ApiAuthLoginRequestBodyUnionEmailLoginRequest> get copyWith => _$ApiAuthLoginRequestBodyUnionEmailLoginRequestCopyWithImpl<ApiAuthLoginRequestBodyUnionEmailLoginRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApiAuthLoginRequestBodyUnionEmailLoginRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiAuthLoginRequestBodyUnionEmailLoginRequest&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,password);

@override
String toString() {
  return 'ApiAuthLoginRequestBodyUnion.emailLoginRequest(email: $email, password: $password)';
}


}

/// @nodoc
abstract mixin class $ApiAuthLoginRequestBodyUnionEmailLoginRequestCopyWith<$Res> implements $ApiAuthLoginRequestBodyUnionCopyWith<$Res> {
  factory $ApiAuthLoginRequestBodyUnionEmailLoginRequestCopyWith(ApiAuthLoginRequestBodyUnionEmailLoginRequest value, $Res Function(ApiAuthLoginRequestBodyUnionEmailLoginRequest) _then) = _$ApiAuthLoginRequestBodyUnionEmailLoginRequestCopyWithImpl;
@override @useResult
$Res call({
 String email, String password
});




}
/// @nodoc
class _$ApiAuthLoginRequestBodyUnionEmailLoginRequestCopyWithImpl<$Res>
    implements $ApiAuthLoginRequestBodyUnionEmailLoginRequestCopyWith<$Res> {
  _$ApiAuthLoginRequestBodyUnionEmailLoginRequestCopyWithImpl(this._self, this._then);

  final ApiAuthLoginRequestBodyUnionEmailLoginRequest _self;
  final $Res Function(ApiAuthLoginRequestBodyUnionEmailLoginRequest) _then;

/// Create a copy of ApiAuthLoginRequestBodyUnion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? password = null,}) {
  return _then(ApiAuthLoginRequestBodyUnionEmailLoginRequest(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
