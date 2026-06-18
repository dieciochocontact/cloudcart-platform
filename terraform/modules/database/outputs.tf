output "db_endpoint" {
  value = aws_db_instance.main.address
}

output "db_security_group_id" {
  value = aws_security_group.db.id
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db_password.arn
}