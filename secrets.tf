# Create the Secrets Manager secret
resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "rds_app_credentials"
  description             = "RDS database credentials for the business automation app"
  recovery_window_in_days = 7

  tags = merge(
    {
      Name = "rds-app-credentials"
    },
    var.common_tags
  )
}

# Store the secret value
resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    DB_HOST = split(":", module.rds.db_instance_endpoint)[0]  # Strip the port
    DB_USER = data.aws_ssm_parameter.db_username.value
    DB_PASS = data.aws_ssm_parameter.db_password.value
    DB_NAME = var.db_name
  })
}
