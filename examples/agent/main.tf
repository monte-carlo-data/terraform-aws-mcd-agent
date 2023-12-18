data "aws_region" "current" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name               = "apollo-vpc"
  cidr               = "10.0.0.0/16"
  azs                = formatlist("${data.aws_region.current.name}%s", ["a", "b"])
  private_subnets    = ["10.0.0.0/24", "10.0.1.0/24"]
  public_subnets     = ["10.0.2.0/24", "10.0.3.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id          = module.vpc.vpc_id
  service_name    = "com.amazonaws.${data.aws_region.current.name}.s3"
  route_table_ids = concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids)
}

module "apollo" {
  source = "../../"

  cloud_account_id = "682816785079"
  image            = "404798114945.dkr.ecr.*.amazonaws.com/mcd-pre-release-agent:latest"
  region           = data.aws_region.current.name
  private_subnets  = module.vpc.private_subnets
}

output "function_arn" {
  value       = module.apollo.mcd_agent_function_arn
  description = "Agent Function ARN. To be used in registering."
}

output "invoker_role_arn" {
  value       = module.apollo.mcd_agent_invoker_role_arn
  description = "Assumable role ARN. To be used in registering."
}

output "invoker_role_external_id" {
  value       = module.apollo.mcd_agent_invoker_role_external_id
  description = "Assumable role External ID. To be used in registering."
}

output "public_ip" {
  value       = module.vpc.nat_public_ips
  description = "IP address from which agent resources access the Internet (e.g. for IP whitelisting)."
}