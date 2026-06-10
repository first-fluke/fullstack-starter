# ElastiCache Redis 7
resource "aws_elasticache_subnet_group" "main" {
  name       = local.name_prefix
  subnet_ids = aws_subnet.private[*].id

  tags = { Name = "${local.name_prefix}-redis-subnet-group" }
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = local.name_prefix
  description          = "Redis 7 for ${var.app_name} ${var.environment}"

  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.redis_node_type
  num_cache_clusters   = var.environment == "prod" ? 2 : 1
  port                 = 6379
  parameter_group_name = "default.redis7"

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  automatic_failover_enabled = var.environment == "prod"

  snapshot_retention_limit = var.environment == "prod" ? 7 : 0

  tags = { Name = "${local.name_prefix}-redis" }
}
