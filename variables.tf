variable "image" {
  description = "URI of the Agent container image (ECR Repo). Note that the region is automatically derived from the region variable."
  type        = string
  default     = "752656882040.dkr.ecr.*.amazonaws.com/mcd-agent:latest"
}

variable "cloud_account_id" {
  description = <<EOF
    Select the Monte Carlo account your collection service is hosted in.

    This can be found in the 'settings/integrations/collectors' tab on the UI or via the 'montecarlo collectors list' command on the CLI
  EOF
  type        = string
  default     = "190812797848"
  validation {
    condition     = contains(["190812797848", "799135046351", "682816785079", "637423407294", "590183797493"], var.cloud_account_id)
    error_message = "Valid value is one of the following: 190812797848, 799135046351, 682816785079, 637423407294, 590183797493."
  }
}

variable "private_subnets" {
  description = "Optionally connect the agent to a VPC by specifying at least two private subnet IDs in that VPC."
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.private_subnets) == 0 || length(var.private_subnets) >= 2
    error_message = "At least two subnets are required if connecting to a VPC."
  }
}

variable "region" {
  description = "The AWS region to deploy the agent into."
  type        = string
  default     = "us-east-1" # Northern Virginia
}

variable "remote_upgradable" {
  description = <<EOF
    Allow the agent image and configuration to be remotely upgraded by Monte Carlo.

    Note that this sets a lifecycle to ignore any changes in Terraform to the image used after the initial deployment.

    If not set to 'true' you will be responsible for upgrading the image (e.g. specifying a new tag) for any bug fixes and improvements.

    Changing this value after initial deployment might replace your agent and require (re)registration.
  EOF
  type        = bool
  default     = true
}