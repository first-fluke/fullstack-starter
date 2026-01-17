// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServiceStatus _$ServiceStatusFromJson(Map<String, dynamic> json) =>
    _ServiceStatus(
      status: ServiceStatusStatus.fromJson(json['status'] as String),
      latencyMs: json['latency_ms'] as num?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$ServiceStatusToJson(_ServiceStatus instance) =>
    <String, dynamic>{
      'status': _$ServiceStatusStatusEnumMap[instance.status]!,
      'latency_ms': instance.latencyMs,
      'error': instance.error,
    };

const _$ServiceStatusStatusEnumMap = {
  ServiceStatusStatus.healthy: 'healthy',
  ServiceStatusStatus.unhealthy: 'unhealthy',
  ServiceStatusStatus.$unknown: r'$unknown',
};
