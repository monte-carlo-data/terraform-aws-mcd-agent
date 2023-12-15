output "mcd_agent_function_arn" {
  value       = var.remote_upgradable ? aws_lambda_function.mcd_agent_service_with_remote_upgrade_support[0].arn : aws_lambda_function.mcd_agent_service[0].arn
  description = "Agent Function ARN. To be used in registering."
}

output "mcd_agent_invoker_role_arn" {
  value       = aws_iam_role.mcd_agent_service_invocation_role.arn
  description = "Assumable role ARN. To be used in registering."
}

output "mcd_agent_invoker_role_external_id" {
  value       = random_id.mcd_agent_id.hex
  description = "Assumable role External ID. To be used in registering."
}

output "mcd_agent_security_group_name" {
  value       = local.connect_to_vpc ? aws_security_group.mcd_agent_vpc_sg[0].name : null
  description = "Security group ID."
}

output "mcd_agent_storage_bucket_arn" {
  value       = aws_s3_bucket.mcd_agent_store.arn
  description = "Storage bucket ARN."
}