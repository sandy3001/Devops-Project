data "aws_secretsmanager_secret" "db" {
  name = "db-credentials"
}

data "aws_secretsmanager_secret_version" "db" {
  secret_id = data.aws_secretsmanager_secret.db.id
}
