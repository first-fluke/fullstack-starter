// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_exchange_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionExchangeRequest {

@JsonKey(name: 'session_token') String get sessionToken;
/// Create a copy of SessionExchangeRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionExchangeRequestCopyWith<SessionExchangeRequest> get copyWith => _$SessionExchangeRequestCopyWithImpl<SessionExchangeRequest>(this as SessionExchangeRequest, _$identity);

  /// Serializes this SessionExchangeRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionExchangeRequest&&(identical(other.sessionToken, sessionToken) || other.sessionToken == sessionToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionToken);

@override
String toString() {
  return 'SessionExchangeRequest(sessionToken: $sessionToken)';
}


}

/// @nodoc
abstract mixin class $SessionExchangeRequestCopyWith<$Res>  {
  factory $SessionExchangeRequestCopyWith(SessionExchangeRequest value, $Res Function(SessionExchangeRequest) _then) = _$SessionExchangeRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'session_token') String sessionToken
});




}
/// @nodoc
class _$SessionExchangeRequestCopyWithImpl<$Res>
    implements $SessionExchangeRequestCopyWith<$Res> {
  _$SessionExchangeRequestCopyWithImpl(this._self, this._then);

  final SessionExchangeRequest _self;
  final $Res Function(SessionExchangeRequest) _then;

/// Create a copy of SessionExchangeRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionToken = null,}) {
  return _then(_self.copyWith(
sessionToken: null == sessionToken ? _self.sessionToken : sessionToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionExchangeRequest].
extension SessionExchangeRequestPatterns on SessionExchangeRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionExchangeRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionExchangeRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionExchangeRequest value)  $default,){
final _that = this;
switch (_that) {
case _SessionExchangeRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionExchangeRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SessionExchangeRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'session_token')  String sessionToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionExchangeRequest() when $default != null:
return $default(_that.sessionToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'session_token')  String sessionToken)  $default,) {final _that = this;
switch (_that) {
case _SessionExchangeRequest():
return $default(_that.sessionToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'session_token')  String sessionToken)?  $default,) {final _that = this;
switch (_that) {
case _SessionExchangeRequest() when $default != null:
return $default(_that.sessionToken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionExchangeRequest implements SessionExchangeRequest {
  const _SessionExchangeRequest({@JsonKey(name: 'session_token') required this.sessionToken});
  factory _SessionExchangeRequest.fromJson(Map<String, dynamic> json) => _$SessionExchangeRequestFromJson(json);

@override@JsonKey(name: 'session_token') final  String sessionToken;

/// Create a copy of SessionExchangeRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionExchangeRequestCopyWith<_SessionExchangeRequest> get copyWith => __$SessionExchangeRequestCopyWithImpl<_SessionExchangeRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionExchangeRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionExchangeRequest&&(identical(other.sessionToken, sessionToken) || other.sessionToken == sessionToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionToken);

@override
String toString() {
  return 'SessionExchangeRequest(sessionToken: $sessionToken)';
}


}

/// @nodoc
abstract mixin class _$SessionExchangeRequestCopyWith<$Res> implements $SessionExchangeRequestCopyWith<$Res> {
  factory _$SessionExchangeRequestCopyWith(_SessionExchangeRequest value, $Res Function(_SessionExchangeRequest) _then) = __$SessionExchangeRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'session_token') String sessionToken
});




}
/// @nodoc
class __$SessionExchangeRequestCopyWithImpl<$Res>
    implements _$SessionExchangeRequestCopyWith<$Res> {
  __$SessionExchangeRequestCopyWithImpl(this._self, this._then);

  final _SessionExchangeRequest _self;
  final $Res Function(_SessionExchangeRequest) _then;

/// Create a copy of SessionExchangeRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionToken = null,}) {
  return _then(_SessionExchangeRequest(
sessionToken: null == sessionToken ? _self.sessionToken : sessionToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
