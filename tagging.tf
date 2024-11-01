locals {
  common_tags = {
    "mcd-agent-service-name"    = lower(local.mcd_agent_service_name)
    "mcd-agent-deployment-type" = lower(local.mcd_agent_deployment_type)
  }
}