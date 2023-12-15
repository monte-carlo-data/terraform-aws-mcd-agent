# Monte Carlo AWS Agent Module (Beta)

This module deploys Monte Carlo's [containerized agent](https://hub.docker.com/r/montecarlodata/agent)* (Beta) on AWS
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
| image             | URI of the Agent container image (ECR Repo). Note that the region is automatically derived from the region variable.                                                                                                                                                                                                                                                                                                                        | string       | 752656882040.dkr.ecr.*.amazonaws.com/mcd-agent:latest |
| cloud_account_id  | Select the Monte Carlo account your collection service is hosted in. This can be found in the '[settings/integrations/collectors](https://getmontecarlo.com/settings/integrations/collectors)' tab on the UI or via the '[montecarlo collectors list](https://clidocs.getmontecarlo.com/#montecarlo-collectors-list)' command on the CLI                                                                                                    | string       | 190812797848                                          |
| private_subnets   | Optionally connect the agent to a VPC by specifying at least two private subnet IDs in that VPC.                                                                                                                                                                                                                                                                                                                                            | list(string) | []                                                    |
| region            | The AWS region to deploy the agent into.                                                                                                                                                                                                                                                                                                                                                                                                    | string       | us-east-1                                             |
| remote_upgradable | Allow the agent image and configuration to be remotely upgraded by Monte Carlo. Note that this sets a lifecycle to ignore any changes in Terraform to the image used after the initial deployment. If not set to 'true' you will be responsible for upgrading the image (e.g. specifying a new tag) for any bug fixes and improvements. Changing this value after initial deployment might replace your agent and require (re)registration. | bool         | true                                                  |

## Outputs

| **Name**                           | **Description**                                        |
|------------------------------------|--------------------------------------------------------|
| mcd_agent_function_arn             | Agent Function ARN. To be used in registering.         |
| mcd_agent_invoker_role_arn         | Assumable role ARN. To be used in registering.         |
| mcd_agent_invoker_role_external_id | Assumable role External ID. To be used in registering. |
| mcd_agent_security_group_name      | Security group ID.                                     |
| mcd_agent_storage_bucket_arn       | Storage bucket ARN.                                    |

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