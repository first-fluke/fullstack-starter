// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'http_validation_error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HttpValidationError {

 List<ValidationError>? get detail;
/// Create a copy of HttpValidationError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HttpValidationErrorCopyWith<HttpValidationError> get copyWith => _$HttpValidationErrorCopyWithImpl<HttpValidationError>(this as HttpValidationError, _$identity);

  /// Serializes this HttpValidationError to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HttpValidationError&&const DeepCollectionEquality().equals(other.detail, detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(detail));

@override
String toString() {
  return 'HttpValidationError(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $HttpValidationErrorCopyWith<$Res>  {
  factory $HttpValidationErrorCopyWith(HttpValidationError value, $Res Function(HttpValidationError) _then) = _$HttpValidationErrorCopyWithImpl;
@useResult
$Res call({
 List<ValidationError>? detail
});




}
/// @nodoc
class _$HttpValidationErrorCopyWithImpl<$Res>
    implements $HttpValidationErrorCopyWith<$Res> {
  _$HttpValidationErrorCopyWithImpl(this._self, this._then);

  final HttpValidationError _self;
  final $Res Function(HttpValidationError) _then;

/// Create a copy of HttpValidationError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? detail = freezed,}) {
  return _then(_self.copyWith(
detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as List<ValidationError>?,
  ));
}

}


/// Adds pattern-matching-related methods to [HttpValidationError].
extension HttpValidationErrorPatterns on HttpValidationError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HttpValidationError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HttpValidationError() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HttpValidationError value)  $default,){
final _that = this;
switch (_that) {
case _HttpValidationError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HttpValidationError value)?  $default,){
final _that = this;
switch (_that) {
case _HttpValidationError() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ValidationError>? detail)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HttpValidationError() when $default != null:
return $default(_that.detail);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ValidationError>? detail)  $default,) {final _that = this;
switch (_that) {
case _HttpValidationError():
return $default(_that.detail);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ValidationError>? detail)?  $default,) {final _that = this;
switch (_that) {
case _HttpValidationError() when $default != null:
return $default(_that.detail);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HttpValidationError implements HttpValidationError {
  const _HttpValidationError({final  List<ValidationError>? detail}): _detail = detail;
  factory _HttpValidationError.fromJson(Map<String, dynamic> json) => _$HttpValidationErrorFromJson(json);

 final  List<ValidationError>? _detail;
@override List<ValidationError>? get detail {
  final value = _detail;
  if (value == null) return null;
  if (_detail is EqualUnmodifiableListView) return _detail;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of HttpValidationError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HttpValidationErrorCopyWith<_HttpValidationError> get copyWith => __$HttpValidationErrorCopyWithImpl<_HttpValidationError>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HttpValidationErrorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HttpValidationError&&const DeepCollectionEquality().equals(other._detail, _detail));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_detail));

@override
String toString() {
  return 'HttpValidationError(detail: $detail)';
}


}

/// @nodoc
abstract mixin class _$HttpValidationErrorCopyWith<$Res> implements $HttpValidationErrorCopyWith<$Res> {
  factory _$HttpValidationErrorCopyWith(_HttpValidationError value, $Res Function(_HttpValidationError) _then) = __$HttpValidationErrorCopyWithImpl;
@override @useResult
$Res call({
 List<ValidationError>? detail
});




}
/// @nodoc
class __$HttpValidationErrorCopyWithImpl<$Res>
    implements _$HttpValidationErrorCopyWith<$Res> {
  __$HttpValidationErrorCopyWithImpl(this._self, this._then);

  final _HttpValidationError _self;
  final $Res Function(_HttpValidationError) _then;

/// Create a copy of HttpValidationError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? detail = freezed,}) {
  return _then(_HttpValidationError(
detail: freezed == detail ? _self._detail : detail // ignore: cast_nullable_to_non_nullable
as List<ValidationError>?,
  ));
}


}

// dart format on
