// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HealthResponse _$HealthResponseFromJson(Map<String, dynamic> json) =>
    _HealthResponse(
      status: HealthResponseStatus.fromJson(json['status'] as String),
      services: (json['services'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, ServiceStatus.fromJson(e as Map<String, dynamic>)),
      ),
      version: json['version'] as String? ?? '0.1.0',
    );

Map<String, dynamic> _$HealthResponseToJson(_HealthResponse instance) =>
    <String, dynamic>{
      'status': _$HealthResponseStatusEnumMap[instance.status]!,
      'services': instance.services,
      'version': instance.version,
    };

const _$HealthResponseStatusEnumMap = {
  HealthResponseStatus.healthy: 'healthy',
  HealthResponseStatus.degraded: 'degraded',
  HealthResponseStatus.unhealthy: 'unhealthy',
  HealthResponseStatus.$unknown: r'$unknown',
};
