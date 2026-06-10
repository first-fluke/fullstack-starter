# Aurora PostgreSQL 16
resource "aws_db_subnet_group" "main" {
  name       = local.name_prefix
  subnet_ids = aws_subnet.private[*].id

  tags = { Name = "${local.name_prefix}-db-subnet-group" }
}

resource "aws_rds_cluster_parameter_group" "main" {
  name   = "${local.name_prefix}-aurora-pg16"
  family = "aurora-postgresql16"

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
    apply_method = "pending-reboot"
  }

  tags = { Name = "${local.name_prefix}-aurora-pg16" }
}

resource "aws_rds_cluster" "main" {
  cluster_identifier = local.name_prefix
  engine             = "aurora-postgresql"
  engine_version     = "16.4"
  database_name      = var.db_name
  master_username    = var.db_user

  # Password injected via Infisical as TF_VAR_DATABASE_PASSWORD
  master_password = var.DATABASE_PASSWORD

  db_subnet_group_name            = aws_db_subnet_group.main.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  vpc_security_group_ids          = [aws_security_group.db.id]

  storage_encrypted = true
  storage_type      = "aurora"

  backup_retention_period = var.rds_backup_retention_period
  preferred_backup_window = "03:00-04:00"
  copy_tags_to_snapshot   = true

  deletion_protection = var.rds_deletion_protection
  skip_final_snapshot = !var.rds_deletion_protection

  final_snapshot_identifier = var.rds_deletion_protection ? "${local.name_prefix}-final" : null

  tags = { Name = "${local.name_prefix}-aurora" }
}

# Read scaling guide: with rds_multi_az the second instance is a failover
# standby AND an Aurora reader, but the apps only use the writer endpoint.
# To offload reads at high traffic:
#   1. raise the instance count (Aurora supports up to 15 readers)
#   2. expose aws_rds_cluster.main.reader_endpoint as DATABASE_READ_HOST
#      in ecs.tf local.backend_environment
#   3. route read-only queries to it in the application layer
# For connection pooling at scale, put RDS Proxy in front of both endpoints.
resource "aws_rds_cluster_instance" "main" {
  count              = var.rds_multi_az ? 2 : 1
  identifier         = "${local.name_prefix}-${count.index}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.db_instance_class
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  performance_insights_enabled = true

  tags = { Name = "${local.name_prefix}-aurora-${count.index}" }
}
