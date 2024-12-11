output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main_vpc.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private_subnets[*].id
}

output "security_group_id" {
  description = "The ID of the ECS security group"
  value       = aws_security_group.ecs_sg.id
}
output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}
output "aws_cloudwatch_log_group" {
  value = [for log_group in aws_cloudwatch_log_group.ecs_cw_log_group:  log_group.name]
}

output "aws_ecs_cluster" {
  value = aws_ecs_cluster.ecs_cluster.arn
}
