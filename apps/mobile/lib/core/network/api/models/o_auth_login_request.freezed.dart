// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'o_auth_login_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OAuthLoginRequest {

 OAuthLoginRequestProvider get provider;@JsonKey(name: 'access_token') String get accessToken; String get email; String? get name;
/// Create a copy of OAuthLoginRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OAuthLoginRequestCopyWith<OAuthLoginRequest> get copyWith => _$OAuthLoginRequestCopyWithImpl<OAuthLoginRequest>(this as OAuthLoginRequest, _$identity);

  /// Serializes this OAuthLoginRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OAuthLoginRequest&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.email, email) || other.email == email)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,accessToken,email,name);

@override
String toString() {
  return 'OAuthLoginRequest(provider: $provider, accessToken: $accessToken, email: $email, name: $name)';
}


}

/// @nodoc
abstract mixin class $OAuthLoginRequestCopyWith<$Res>  {
  factory $OAuthLoginRequestCopyWith(OAuthLoginRequest value, $Res Function(OAuthLoginRequest) _then) = _$OAuthLoginRequestCopyWithImpl;
@useResult
$Res call({
 OAuthLoginRequestProvider provider,@JsonKey(name: 'access_token') String accessToken, String email, String? name
});




}
/// @nodoc
class _$OAuthLoginRequestCopyWithImpl<$Res>
    implements $OAuthLoginRequestCopyWith<$Res> {
  _$OAuthLoginRequestCopyWithImpl(this._self, this._then);

  final OAuthLoginRequest _self;
  final $Res Function(OAuthLoginRequest) _then;

/// Create a copy of OAuthLoginRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = null,Object? accessToken = null,Object? email = null,Object? name = freezed,}) {
  return _then(_self.copyWith(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as OAuthLoginRequestProvider,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OAuthLoginRequest].
extension OAuthLoginRequestPatterns on OAuthLoginRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OAuthLoginRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OAuthLoginRequest() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OAuthLoginRequest value)  $default,){
final _that = this;
switch (_that) {
case _OAuthLoginRequest():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OAuthLoginRequest value)?  $default,){
final _that = this;
switch (_that) {
case _OAuthLoginRequest() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OAuthLoginRequestProvider provider, @JsonKey(name: 'access_token')  String accessToken,  String email,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OAuthLoginRequest() when $default != null:
return $default(_that.provider,_that.accessToken,_that.email,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OAuthLoginRequestProvider provider, @JsonKey(name: 'access_token')  String accessToken,  String email,  String? name)  $default,) {final _that = this;
switch (_that) {
case _OAuthLoginRequest():
return $default(_that.provider,_that.accessToken,_that.email,_that.name);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OAuthLoginRequestProvider provider, @JsonKey(name: 'access_token')  String accessToken,  String email,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _OAuthLoginRequest() when $default != null:
return $default(_that.provider,_that.accessToken,_that.email,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OAuthLoginRequest implements OAuthLoginRequest {
  const _OAuthLoginRequest({required this.provider, @JsonKey(name: 'access_token') required this.accessToken, required this.email, this.name});
  factory _OAuthLoginRequest.fromJson(Map<String, dynamic> json) => _$OAuthLoginRequestFromJson(json);

@override final  OAuthLoginRequestProvider provider;
@override@JsonKey(name: 'access_token') final  String accessToken;
@override final  String email;
@override final  String? name;

/// Create a copy of OAuthLoginRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OAuthLoginRequestCopyWith<_OAuthLoginRequest> get copyWith => __$OAuthLoginRequestCopyWithImpl<_OAuthLoginRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OAuthLoginRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OAuthLoginRequest&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.email, email) || other.email == email)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provider,accessToken,email,name);

@override
String toString() {
  return 'OAuthLoginRequest(provider: $provider, accessToken: $accessToken, email: $email, name: $name)';
}


}

/// @nodoc
abstract mixin class _$OAuthLoginRequestCopyWith<$Res> implements $OAuthLoginRequestCopyWith<$Res> {
  factory _$OAuthLoginRequestCopyWith(_OAuthLoginRequest value, $Res Function(_OAuthLoginRequest) _then) = __$OAuthLoginRequestCopyWithImpl;
@override @useResult
$Res call({
 OAuthLoginRequestProvider provider,@JsonKey(name: 'access_token') String accessToken, String email, String? name
});




}
/// @nodoc
class __$OAuthLoginRequestCopyWithImpl<$Res>
    implements _$OAuthLoginRequestCopyWith<$Res> {
  __$OAuthLoginRequestCopyWithImpl(this._self, this._then);

  final _OAuthLoginRequest _self;
  final $Res Function(_OAuthLoginRequest) _then;

/// Create a copy of OAuthLoginRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? accessToken = null,Object? email = null,Object? name = freezed,}) {
  return _then(_OAuthLoginRequest(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as OAuthLoginRequestProvider,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
