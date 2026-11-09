# Monte Carlo AWS Agent Module

This module deploys Monte Carlo's [containerized agent](https://hub.docker.com/r/montecarlodata/agent)* on AWS
Lambda, along with storage, roles etc.

See [here](https://docs.getmontecarlo.com/docs/platform-architecture) for architecture details and alternative
deployment options.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.3)
- [AWS CLI](https://aws.amazon.com/cli/).
  [Authentication reference](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)

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

## Inputs

| **Name**          | **Description**                                                                                                                                                                                                                                                                                                                                                                                                                             | **Type**     | **Default**                                           |
|-------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|-------------------------------------------------------|
| image             | URI of the Agent container image (ECR Repo). Note that the region is automatically derived from the region variable. To pin an exact image, reference it by digest (e.g. `mcd-agent@sha256:...`) and set `remote_upgradable` to false.                                                                                                                                                                                                                                                                                                                        | string       | 590183797493.dkr.ecr.*.amazonaws.com/mcd-agent:latest |
| cloud_account_id  | For deployments on the V2 Platform, use 590183797493. Accounts created after April 24th, 2024, will automatically be on the V2 platform or newer. If you are using an older version of the platform, please contact your Monte Carlo representative for the ID.                                                                                                                                                                             | string       | 190812797848                                          |
| private_subnets   | Optionally connect the agent to a VPC by specifying at least two private subnet IDs in that VPC.                                                                                                                                                                                                                                                                                                                                            | list(string) | []                                                    |
| region            | The AWS region to deploy the agent into.                                                                                                                                                                                                                                                                                                                                                                                                    | string       | us-east-1                                             |
| remote_upgradable | Allow the agent image and configuration to be remotely upgraded by Monte Carlo. Note that this sets a lifecycle to ignore any changes in Terraform to the image used after the initial deployment. If not set to 'true' you will be responsible for upgrading the image (e.g. specifying a new tag) for any bug fixes and improvements. Changing this value after initial deployment might replace your agent and require (re)registration. | bool         | true                                                  |
| custom_default_tags | Merge custom tags into the default_tags of the aws provider | map(string) | {}
| additional_env_vars | Additional environment variables to set on the agent, as a map of name to value. Advanced/optional; used to enable optional agent features. | map(string) | {}
| external_id | External ID generated by Monte Carlo when registering this deployment. Required for new deployments. Copy it from the External ID field on the agent registration page in Monte Carlo. Leave blank only for existing deployments that already use the random ID generated by this module. | string | "" |
| invocation_source_vpce_ids | Optionally restrict agent invocation to these VPC endpoint IDs (aws:SourceVpce). Use the Agent VPC endpoint ID listed for the agent's region on the Monte Carlo Account information page. Leave empty to allow invocation from any source. | list(string) | [] |
| security_group_ids | Optionally attach your own security groups to the agent instead of the one created by this module. Only used when `private_subnets` is set. Use this to restrict egress, e.g. to VPC endpoints and the specific data sources the agent connects to. The module-created security group allows all outbound traffic. | list(string) | [] |
| s3_kms_key_arn | Optionally encrypt the agent storage bucket with this customer managed KMS key (SSE-KMS) instead of Amazon S3 managed keys (SSE-S3). The agent execution role is granted `kms:GenerateDataKey` and `kms:Decrypt` on the key; the key policy must allow this account's IAM principals to use it. | string | "" |
| s3_versioning_enabled | Enable versioning on the agent storage bucket. Noncurrent versions expire on the same schedule as current objects. | bool | false |

## Outputs

| **Name**                           | **Description**                                        |
|------------------------------------|--------------------------------------------------------|
| mcd_agent_function_arn             | Agent Function ARN. To be used in registering.         |
| mcd_agent_invoker_role_arn         | Assumable role ARN. To be used in registering.         |
| mcd_agent_invoker_role_external_id | Assumable role External ID. To be used in registering. |
| mcd_agent_security_group_name      | Name of the security group created by this module. Null when not connected to a VPC or when `security_group_ids` is set. |
| mcd_agent_storage_bucket_arn       | Storage bucket ARN.                                    |
| mcd_agent_storage_bucket_name      | Storage bucket name.                                   |
| mcd_agent_execution_role           | The role the MCD agent will use to execute actions.    |

## Hardening

The defaults favor a working deployment with minimal setup. For environments with stricter controls:

- **Egress**: the module-created security group allows all outbound traffic. Pass `security_group_ids` with your own
  security groups to limit egress to VPC endpoints (S3, STS, CloudWatch Logs, Secrets Manager, KMS) and the data
  sources the agent connects to. Note that SaaS data sources (e.g. Snowflake) need either PrivateLink or a route to
  their public endpoints.
- **Encryption and versioning**: set `s3_kms_key_arn` to encrypt the storage bucket with your own KMS key, and
  `s3_versioning_enabled` to keep prior object versions until they expire.
- **Image pinning**: Lambda resolves the image tag to a digest at deploy time, so the running code only changes when
  the function is redeployed or remotely upgraded. To control exactly which image runs, set `remote_upgradable` to
  false and reference the image by digest, e.g.
  `590183797493.dkr.ecr.*.amazonaws.com/mcd-agent@sha256:<digest>`. You can also mirror the image into your own ECR
  registry (e.g. with an ECR pull through cache rule), scan it there, and point `image` at your copy.

## Releases and Development

The README and sample agent in the `examples/agent` directory is a good starting point to familiarize
yourself with using the agent.

Note that all Terraform files must conform to the standards of `terraform fmt` and
the [standard module structure](https://developer.hashicorp.com/terraform/language/modules/develop).
CircleCI will sanity check formatting and for valid tf config files. Run `make test` for the offline module tests.
It is also recommended you use Terraform Cloud as a backend.
Otherwise, as normal, please follow Monte Carlo's code guidelines during development and review.

When ready to release, set `mcd_wrapper_version` in `main.tf` to the version being released (it is reported to
Monte Carlo as `MCD_AGENT_WRAPPER_VERSION` and is not bumped automatically), then add the matching version tag, e.g.
v0.0.42, and push that tag to GitHub.
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
