output "cluster_endpoint" {
  description = "Aurora cluster endpoint."
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Aurora reader endpoint."
  value       = aws_rds_cluster.this.reader_endpoint
}

output "db_cluster_identifier" {
  description = "Aurora cluster identifier."
  value       = aws_rds_cluster.this.id
}
