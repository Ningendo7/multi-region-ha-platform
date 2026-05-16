resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-${replace(var.region, "-", "")}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags = {
    Name = "${var.project_name}-${replace(var.region, "-", "")}-db-subnet-group"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-${replace(var.region, "-", "")}-db-sg"
  description = "Database security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${replace(var.region, "-", "")}-db-sg"
  }
}

resource "aws_rds_cluster" "this" {
  cluster_identifier      = "${var.project_name}-${replace(var.region, "-", "")}-db-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = var.db_engine_version
  database_name           = var.db_name
  master_username         = var.db_username
  master_password         = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.id
  vpc_security_group_ids  = [aws_security_group.db.id]
  backup_retention_period = 7
  preferred_backup_window = "07:00-09:00"
  storage_encrypted       = true
  skip_final_snapshot     = true
  tags = {
    Name = "${var.project_name}-${replace(var.region, "-", "")}-db-cluster"
  }
}

resource "aws_rds_cluster_instance" "writer" {
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.db_instance_class
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version
  publicly_accessible = false
  tags = {
    Name = "${var.project_name}-${replace(var.region, "-", "")}-db-instance"
  }
}
