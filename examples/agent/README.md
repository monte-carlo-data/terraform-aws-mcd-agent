# Agent Sample

This example deploys a pre-release Agent that is connected to a VPC. The VPC is created
with the help of [this](https://github.com/terraform-aws-modules/terraform-aws-vpc) module.

Note that the pre-release agent is in active development and not intended for production usage.

## Prerequisites

See the Prerequisites subsection in the module.

## Usage

To provision this example and access (test) the agent locally:

```
make exec profile=<AWS_PROFILE>
```

Note that this convenience command auto-approves the plan, and executes a test request. To review
interactively please use `terraform plan + apply` instead.

See [here](https://github.com/monte-carlo-data/apollo-agent) for agent usage and docs. You should be able to use any
endpoint as documented.

And don't forget to delete any resources when you're done (e.g. `terraform destroy`).

## Addendum

During development, you might want configure Terraform Cloud as the backend. To do so you can add the following snippet:

```
terraform {
  cloud {
    organization = "<org>"

    workspaces {
      name = "<workspace>"
    }
  }
}
```

This also requires you to execute `terraform login` before initializing. You will also either have to update the
working directory to include the agent module or set the execution mode to "Local".