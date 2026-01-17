// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServiceStatus {

 ServiceStatusStatus get status;@JsonKey(name: 'latency_ms') num? get latencyMs; String? get error;
/// Create a copy of ServiceStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceStatusCopyWith<ServiceStatus> get copyWith => _$ServiceStatusCopyWithImpl<ServiceStatus>(this as ServiceStatus, _$identity);

  /// Serializes this ServiceStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceStatus&&(identical(other.status, status) || other.status == status)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,latencyMs,error);

@override
String toString() {
  return 'ServiceStatus(status: $status, latencyMs: $latencyMs, error: $error)';
}


}

/// @nodoc
abstract mixin class $ServiceStatusCopyWith<$Res>  {
  factory $ServiceStatusCopyWith(ServiceStatus value, $Res Function(ServiceStatus) _then) = _$ServiceStatusCopyWithImpl;
@useResult
$Res call({
 ServiceStatusStatus status,@JsonKey(name: 'latency_ms') num? latencyMs, String? error
});




}
/// @nodoc
class _$ServiceStatusCopyWithImpl<$Res>
    implements $ServiceStatusCopyWith<$Res> {
  _$ServiceStatusCopyWithImpl(this._self, this._then);

  final ServiceStatus _self;
  final $Res Function(ServiceStatus) _then;

/// Create a copy of ServiceStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? latencyMs = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ServiceStatusStatus,latencyMs: freezed == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as num?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceStatus].
extension ServiceStatusPatterns on ServiceStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceStatus value)  $default,){
final _that = this;
switch (_that) {
case _ServiceStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceStatus value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ServiceStatusStatus status, @JsonKey(name: 'latency_ms')  num? latencyMs,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceStatus() when $default != null:
return $default(_that.status,_that.latencyMs,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ServiceStatusStatus status, @JsonKey(name: 'latency_ms')  num? latencyMs,  String? error)  $default,) {final _that = this;
switch (_that) {
case _ServiceStatus():
return $default(_that.status,_that.latencyMs,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ServiceStatusStatus status, @JsonKey(name: 'latency_ms')  num? latencyMs,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _ServiceStatus() when $default != null:
return $default(_that.status,_that.latencyMs,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceStatus implements ServiceStatus {
  const _ServiceStatus({required this.status, @JsonKey(name: 'latency_ms') this.latencyMs, this.error});
  factory _ServiceStatus.fromJson(Map<String, dynamic> json) => _$ServiceStatusFromJson(json);

@override final  ServiceStatusStatus status;
@override@JsonKey(name: 'latency_ms') final  num? latencyMs;
@override final  String? error;

/// Create a copy of ServiceStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceStatusCopyWith<_ServiceStatus> get copyWith => __$ServiceStatusCopyWithImpl<_ServiceStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceStatus&&(identical(other.status, status) || other.status == status)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,latencyMs,error);

@override
String toString() {
  return 'ServiceStatus(status: $status, latencyMs: $latencyMs, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ServiceStatusCopyWith<$Res> implements $ServiceStatusCopyWith<$Res> {
  factory _$ServiceStatusCopyWith(_ServiceStatus value, $Res Function(_ServiceStatus) _then) = __$ServiceStatusCopyWithImpl;
@override @useResult
$Res call({
 ServiceStatusStatus status,@JsonKey(name: 'latency_ms') num? latencyMs, String? error
});




}
/// @nodoc
class __$ServiceStatusCopyWithImpl<$Res>
    implements _$ServiceStatusCopyWith<$Res> {
  __$ServiceStatusCopyWithImpl(this._self, this._then);

  final _ServiceStatus _self;
  final $Res Function(_ServiceStatus) _then;

/// Create a copy of ServiceStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? latencyMs = freezed,Object? error = freezed,}) {
  return _then(_ServiceStatus(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ServiceStatusStatus,latencyMs: freezed == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as num?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
