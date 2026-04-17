// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'service_status_status.dart';

part 'service_status.freezed.dart';
part 'service_status.g.dart';

/// Individual service health status.
@Freezed()
abstract class ServiceStatus with _$ServiceStatus {
  const factory ServiceStatus({
    required ServiceStatusStatus status,
    @JsonKey(name: 'latency_ms') num? latencyMs,
    String? error,
  }) = _ServiceStatus;

  factory ServiceStatus.fromJson(Map<String, Object?> json) =>
      _$ServiceStatusFromJson(json);
}
