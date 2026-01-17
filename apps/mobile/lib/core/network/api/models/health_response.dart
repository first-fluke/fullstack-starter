// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'health_response_status.dart';
import 'service_status.dart';

part 'health_response.freezed.dart';
part 'health_response.g.dart';

/// Health check response with detailed service statuses.
@Freezed()
abstract class HealthResponse with _$HealthResponse {
  const factory HealthResponse({
    required HealthResponseStatus status,
    required Map<String, ServiceStatus> services,
    @Default('0.1.0')
    String version,
  }) = _HealthResponse;
  
  factory HealthResponse.fromJson(Map<String, Object?> json) => _$HealthResponseFromJson(json);
}
