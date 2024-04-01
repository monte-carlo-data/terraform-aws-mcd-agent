# Monte Carlo AWS Agent Module (Beta)

This module deploys Monte Carlo's [containerized agent](https://hub.docker.com/r/montecarlodata/agent)* (Beta) on AWS
Lambda, along with storage, roles etc.

See [here](https://docs.getmontecarlo.com/docs/platform-architecture) for architecture details and alternative
deployment options.


## Usage

Basic usage of this module:

```
module "apollo" {
  source = "monte-carlo-data/mcd-agent/aws"
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
```

After which you must register your agent with Monte Carlo. See
[here](https://docs.getmontecarlo.com/docs/create-and-register-an-aws-agent) for more details, options, and
documentation.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.40.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.mcd_agent_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.mcd_agent_service_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.mcd_agent_service_invocation_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.mcd_agent_service_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.mcd_agent_service_lambda_info_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.mcd_agent_service_lambda_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.mcd_agent_service_lambda_stop_query_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.mcd_agent_service_lambda_update_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.mcd_agent_service_repo_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.mcd_agent_service_s3_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_function.mcd_agent_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.mcd_agent_service_with_remote_upgrade_support](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_s3_bucket.mcd_agent_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_cors_configuration.mcd_agent_store_cors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.mcd_agent_store_lifecycle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.mcd_agent_store_ssl_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.mcd_agent_store_block_public_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.mcd_agent_store_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_security_group.mcd_agent_vpc_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [random_id.mcd_agent_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_subnet.first_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloud_account_id"></a> [cloud\_account\_id](#input\_cloud\_account\_id) | Select the Monte Carlo account your collection service is hosted in.<br><br>    This can be found in the 'settings/integrations/collectors' tab on the UI or via the 'montecarlo collectors list' command on the CLI | `string` | `"190812797848"` | no |
| <a name="input_image"></a> [image](#input\_image) | URI of the Agent container image (ECR Repo). Note that the region is automatically derived from the region variable. | `string` | `"752656882040.dkr.ecr.*.amazonaws.com/mcd-agent:latest"` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | Optionally connect the agent to a VPC by specifying at least two private subnet IDs in that VPC. | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region to deploy the agent into. | `string` | `"us-east-1"` | no |
| <a name="input_remote_upgradable"></a> [remote\_upgradable](#input\_remote\_upgradable) | Allow the agent image and configuration to be remotely upgraded by Monte Carlo.<br><br>    Note that this sets a lifecycle to ignore any changes in Terraform to the image used after the initial deployment.<br><br>    If not set to 'true' you will be responsible for upgrading the image (e.g. specifying a new tag) for any bug fixes and improvements.<br><br>    Changing this value after initial deployment might replace your agent and require (re)registration. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_mcd_agent_function_arn"></a> [mcd\_agent\_function\_arn](#output\_mcd\_agent\_function\_arn) | Agent Function ARN. To be used in registering. |
| <a name="output_mcd_agent_invoker_role_arn"></a> [mcd\_agent\_invoker\_role\_arn](#output\_mcd\_agent\_invoker\_role\_arn) | Assumable role ARN. To be used in registering. |
| <a name="output_mcd_agent_invoker_role_external_id"></a> [mcd\_agent\_invoker\_role\_external\_id](#output\_mcd\_agent\_invoker\_role\_external\_id) | Assumable role External ID. To be used in registering. |
| <a name="output_mcd_agent_security_group_name"></a> [mcd\_agent\_security\_group\_name](#output\_mcd\_agent\_security\_group\_name) | Security group ID. |
| <a name="output_mcd_agent_storage_bucket_arn"></a> [mcd\_agent\_storage\_bucket\_arn](#output\_mcd\_agent\_storage\_bucket\_arn) | Storage bucket ARN. |
<!-- END_TF_DOCS -->

## Releases and Development

The README and sample agent in the `examples/agent` directory is a good starting point to familiarize
yourself with using the agent.

Note that all Terraform files must conform to the standards of `terraform fmt` and
the [standard module structure](https://developer.hashicorp.com/terraform/language/modules/develop).
CircleCI will sanity check formatting and for valid tf config files.
It is also recommended you use Terraform Cloud as a backend.
Otherwise, as normal, please follow Monte Carlo's code guidelines during development and review.

When ready to release simply add a new version tag, e.g. v0.0.42, and push that tag to GitHub.
See additional
details [here](https://developer.hashicorp.com/terraform/registry/modules/publish#releasing-new-versions).

## License

See [LICENSE](LICENSE) for more information.

## Security

See [SECURITY](SECURITY.md) for more
information.

---
*Note that due to an AWS limitation the agent image is also uploaded and then sourced from AWS ECR when executed on
Lambda.