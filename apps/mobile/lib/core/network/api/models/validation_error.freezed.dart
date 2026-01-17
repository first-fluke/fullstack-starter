// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'validation_error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ValidationError {

 List<dynamic> get loc; String get msg; String get type;
/// Create a copy of ValidationError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValidationErrorCopyWith<ValidationError> get copyWith => _$ValidationErrorCopyWithImpl<ValidationError>(this as ValidationError, _$identity);

  /// Serializes this ValidationError to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValidationError&&const DeepCollectionEquality().equals(other.loc, loc)&&(identical(other.msg, msg) || other.msg == msg)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(loc),msg,type);

@override
String toString() {
  return 'ValidationError(loc: $loc, msg: $msg, type: $type)';
}


}

/// @nodoc
abstract mixin class $ValidationErrorCopyWith<$Res>  {
  factory $ValidationErrorCopyWith(ValidationError value, $Res Function(ValidationError) _then) = _$ValidationErrorCopyWithImpl;
@useResult
$Res call({
 List<dynamic> loc, String msg, String type
});




}
/// @nodoc
class _$ValidationErrorCopyWithImpl<$Res>
    implements $ValidationErrorCopyWith<$Res> {
  _$ValidationErrorCopyWithImpl(this._self, this._then);

  final ValidationError _self;
  final $Res Function(ValidationError) _then;

/// Create a copy of ValidationError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loc = null,Object? msg = null,Object? type = null,}) {
  return _then(_self.copyWith(
loc: null == loc ? _self.loc : loc // ignore: cast_nullable_to_non_nullable
as List<dynamic>,msg: null == msg ? _self.msg : msg // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ValidationError].
extension ValidationErrorPatterns on ValidationError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ValidationError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ValidationError() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ValidationError value)  $default,){
final _that = this;
switch (_that) {
case _ValidationError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ValidationError value)?  $default,){
final _that = this;
switch (_that) {
case _ValidationError() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<dynamic> loc,  String msg,  String type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ValidationError() when $default != null:
return $default(_that.loc,_that.msg,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<dynamic> loc,  String msg,  String type)  $default,) {final _that = this;
switch (_that) {
case _ValidationError():
return $default(_that.loc,_that.msg,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<dynamic> loc,  String msg,  String type)?  $default,) {final _that = this;
switch (_that) {
case _ValidationError() when $default != null:
return $default(_that.loc,_that.msg,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ValidationError implements ValidationError {
  const _ValidationError({required final  List<dynamic> loc, required this.msg, required this.type}): _loc = loc;
  factory _ValidationError.fromJson(Map<String, dynamic> json) => _$ValidationErrorFromJson(json);

 final  List<dynamic> _loc;
@override List<dynamic> get loc {
  if (_loc is EqualUnmodifiableListView) return _loc;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_loc);
}

@override final  String msg;
@override final  String type;

/// Create a copy of ValidationError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ValidationErrorCopyWith<_ValidationError> get copyWith => __$ValidationErrorCopyWithImpl<_ValidationError>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ValidationErrorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ValidationError&&const DeepCollectionEquality().equals(other._loc, _loc)&&(identical(other.msg, msg) || other.msg == msg)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_loc),msg,type);

@override
String toString() {
  return 'ValidationError(loc: $loc, msg: $msg, type: $type)';
}


}

/// @nodoc
abstract mixin class _$ValidationErrorCopyWith<$Res> implements $ValidationErrorCopyWith<$Res> {
  factory _$ValidationErrorCopyWith(_ValidationError value, $Res Function(_ValidationError) _then) = __$ValidationErrorCopyWithImpl;
@override @useResult
$Res call({
 List<dynamic> loc, String msg, String type
});




}
/// @nodoc
class __$ValidationErrorCopyWithImpl<$Res>
    implements _$ValidationErrorCopyWith<$Res> {
  __$ValidationErrorCopyWithImpl(this._self, this._then);

  final _ValidationError _self;
  final $Res Function(_ValidationError) _then;

/// Create a copy of ValidationError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loc = null,Object? msg = null,Object? type = null,}) {
  return _then(_ValidationError(
loc: null == loc ? _self._loc : loc // ignore: cast_nullable_to_non_nullable
as List<dynamic>,msg: null == msg ? _self.msg : msg // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
