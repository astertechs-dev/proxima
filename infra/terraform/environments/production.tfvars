# Production Environment Configuration

environment = "production"
aws_region  = "ap-northeast-1"

# Domain (set your actual domain)
domain_name = "proxima.example.com"

# VPC Configuration
vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.20.0/24"]

# RDS Configuration (production-grade instances)
rds_instance_class        = "db.t3.small"
rds_allocated_storage     = 100
rds_max_allocated_storage = 1000

# DocumentDB Configuration
docdb_instance_class = "db.r5.large"
docdb_instance_count = 2

# ElastiCache Configuration
redis_node_type        = "cache.t3.small"
redis_num_cache_nodes  = 2

# ECS Configuration (production resources)
ecs_cpu           = 512
ecs_memory        = 1024
ecs_desired_count = 2

# Auto Scaling Configuration
ecs_min_capacity  = 2
ecs_max_capacity  = 10
ecs_target_cpu    = 60
ecs_target_memory = 70

# Logging Configuration
log_retention_days = 30

# Monitoring Configuration
enable_detailed_monitoring = true
enable_container_insights  = true

# Backup Configuration
backup_retention_period = 7

# Security Configuration
enable_deletion_protection = true
allowed_cidr_blocks       = ["0.0.0.0/0"]

# Cost Optimization
use_spot_instances = false
enable_nat_gateway = true

# Feature Flags
enable_waf          = true
enable_cloudfront   = true
enable_elasticsearch = false

# Additional Tags
additional_tags = {
  CostCenter = "Production"
  Owner      = "Platform Team"
  Purpose    = "Production"
  Backup     = "Required"
}
