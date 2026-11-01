output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "website_url" {
  value = "http://${aws_lb.app.dns_name}"
}

output "backend_url" {
  value = "http://${aws_lb.app.dns_name}:5000"
}

output "ecs_execution_role_arn" {
  value = aws_iam_role.ecs_execution.arn
}

output "mongo_uri" {
  value     = local.mongo_uri
  sensitive = true
}