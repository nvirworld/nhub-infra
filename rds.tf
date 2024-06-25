resource "aws_rds_cluster_parameter_group" "rds_main" {
  name   = "${local.project}-cpg-rds-main-${local.env}"
  family = "aurora-mysql5.7"
  parameter {
    name         = "binlog_format"
    value        = "ROW"
    apply_method = "pending-reboot"
  }
  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_filesystem"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
  parameter {
    name  = "general_log"
    value = "0"
  }
  parameter {
    name  = "group_concat_max_len"
    value = "65535"
  }
  parameter {
    name  = "lc_time_names"
    value = "en_US"
  }
  parameter {
    name  = "log_bin_trust_function_creators"
    value = "1"
  }
  parameter {
    name  = "long_query_time"
    value = "3"
  }
  parameter {
    name  = "server_audit_events"
    value = "QUERY,QUERY_DCL,QUERY_DDL,QUERY_DML,TABLE"
  }
  parameter {
    name  = "server_audit_excl_users"
    value = "root"
  }
  parameter {
    name  = "server_audit_logging"
    value = "1"
  }
  parameter {
    name  = "server_audit_logs_upload"
    value = "1"
  }
  parameter {
    name  = "slow_launch_time"
    value = "1"
  }
  parameter {
    name  = "slow_query_log"
    value = "1"
  }
  parameter {
    name  = "time_zone"
    value = "Asia/Seoul"
  }
  parameter {
    name  = "max_connections"
    value = "1024"
  }
}

resource "aws_db_parameter_group" "rds_main" {
  name   = "${local.project}-pg-rds-main-${local.env}"
  family = "aurora-mysql5.7"
  parameter {
    name  = "general_log"
    value = "0"
  }
  parameter {
    name  = "long_query_time"
    value = "3"
  }
  parameter {
    name  = "slow_query_log"
    value = "1"
  }
  parameter {
    name  = "max_connections"
    value = "1024"
  }
}

resource "aws_db_subnet_group" "rds_main" {
  name = "${local.project}-subnetgroup-rds-main-${local.env}"
  subnet_ids = [
    aws_subnet.main_public_a.id,
    aws_subnet.main_public_c.id,
  ]
}

resource "aws_security_group" "rds_main" {
  vpc_id = aws_vpc.main.id
  name   = "${local.project}-sg-rds-main-${local.env}"
  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = [
      aws_subnet.main_public_a.cidr_block,
      aws_subnet.main_public_c.cidr_block,
      "0.0.0.0/0",
    ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "${local.project}-sg-rds-main-${local.env}"
  }
}
