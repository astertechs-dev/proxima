# Staging Environment Configuration

environment = "staging"
aws_region  = "ap-northeast-1"

# Domain (leave empty to use ALB DNS)
domain_name = ""

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# RDS Configuration (smaller instances for staging)
rds_instance_class        = "db.t3.micro"
rds_allocated_storage     = 20
rds_max_allocated_storage = 50

# DocumentDB Configuration
docdb_instance_class = "db.t3.medium"
docdb_instance_count = 1

# ElastiCache Configuration
redis_node_type        = "cache.t3.micro"
redis_num_cache_nodes  = 1

# ECS Configuration (smaller resources for staging)
ecs_cpu           = 256
ecs_memory        = 512
ecs_desired_count = 1

# Auto Scaling Configuration
ecs_min_capacity  = 1
ecs_max_capacity  = 3
ecs_target_cpu    = 70
ecs_target_memory = 80

# Logging Configuration
log_retention_days = 3

# Monitoring Configuration
enable_detailed_monitoring = false
enable_container_insights  = false

# Backup Configuration
backup_retention_period = 1

# Security Configuration
enable_deletion_protection = false
allowed_cidr_blocks       = ["0.0.0.0/0"]

# Cost Optimization
use_spot_instances = true
enable_nat_gateway = true

# Feature Flags
enable_waf          = false
enable_cloudfront   = false
enable_elasticsearch = false

# Additional Tags
additional_tags = {
  CostCenter = "Development"
  Owner      = "DevTeam"
  Purpose    = "Staging"
}
