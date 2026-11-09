# Offline tests: the mocked AWS provider needs no credentials. Run with `make test`.
mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }
  mock_data "aws_partition" {
    defaults = {
      id = "aws"
    }
  }
  mock_data "aws_subnet" {
    defaults = {
      vpc_id = "vpc-0123456789abcdef0"
    }
  }
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mcd_agent_service_execution_role"
    }
  }
  mock_resource "aws_lambda_function" {
    defaults = {
      arn = "arn:aws:lambda:us-east-1:123456789012:function:mcd-agent-service"
    }
  }
  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::mcd-agent-store"
    }
  }
}

variables {
  external_id = "test-external-id"
}

run "defaults_are_unchanged" {
  command = apply

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.mcd_agent_store_encryption.rule).apply_server_side_encryption_by_default).sse_algorithm == "AES256"
    error_message = "Default bucket encryption must stay SSE-S3."
  }
  assert {
    condition     = length(aws_s3_bucket_versioning.mcd_agent_store_versioning) == 0
    error_message = "Versioning must be off by default."
  }
  assert {
    condition     = length(aws_iam_role_policy.mcd_agent_service_s3_kms_policy) == 0
    error_message = "No KMS policy without a key."
  }
  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.mcd_agent_store_lifecycle.rule) == 3
    error_message = "Default lifecycle must keep its three rules."
  }
  assert {
    condition     = alltrue([for r in aws_s3_bucket_lifecycle_configuration.mcd_agent_store_lifecycle.rule : length(r.noncurrent_version_expiration) == 0])
    error_message = "No noncurrent expiration without versioning."
  }
  assert {
    condition     = length(aws_security_group.mcd_agent_vpc_sg) == 0
    error_message = "No security group without private subnets."
  }
}

run "kms_and_versioning" {
  command = apply

  variables {
    s3_kms_key_arn        = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"
    s3_versioning_enabled = true
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.mcd_agent_store_encryption.rule).apply_server_side_encryption_by_default).sse_algorithm == "aws:kms"
    error_message = "Bucket must use SSE-KMS when a key is given."
  }
  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.mcd_agent_store_encryption.rule).apply_server_side_encryption_by_default).kms_master_key_id == var.s3_kms_key_arn
    error_message = "Bucket must use the given key."
  }
  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.mcd_agent_store_encryption.rule).bucket_key_enabled == true
    error_message = "S3 bucket keys should be enabled with SSE-KMS."
  }
  assert {
    condition     = jsondecode(aws_iam_role_policy.mcd_agent_service_s3_kms_policy[0].policy).Statement[0].Resource == [var.s3_kms_key_arn]
    error_message = "Execution role must be granted the key."
  }
  assert {
    condition     = one(aws_s3_bucket_versioning.mcd_agent_store_versioning[0].versioning_configuration).status == "Enabled"
    error_message = "Versioning must be enabled."
  }
  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.mcd_agent_store_lifecycle.rule) == 4
    error_message = "Versioned bucket needs the delete-marker rule."
  }
  assert {
    condition     = length([for r in aws_s3_bucket_lifecycle_configuration.mcd_agent_store_lifecycle.rule : r if length(r.noncurrent_version_expiration) == 1]) == 3
    error_message = "Each expiration rule must also expire noncurrent versions."
  }
}

run "vpc_with_module_security_group" {
  command = apply

  variables {
    private_subnets = ["subnet-aaaa", "subnet-bbbb"]
  }

  assert {
    condition     = length(aws_security_group.mcd_agent_vpc_sg) == 1
    error_message = "Module must create its security group by default."
  }
  assert {
    condition     = one(aws_lambda_function.mcd_agent_service_with_remote_upgrade_support[0].vpc_config).security_group_ids == toset([aws_security_group.mcd_agent_vpc_sg[0].id])
    error_message = "Agent must use the module security group."
  }
  assert {
    condition     = output.mcd_agent_security_group_name == aws_security_group.mcd_agent_vpc_sg[0].name
    error_message = "Output must expose the module security group."
  }
}

run "vpc_with_own_security_groups" {
  command = apply

  variables {
    private_subnets    = ["subnet-aaaa", "subnet-bbbb"]
    security_group_ids = ["sg-restricted-egress"]
  }

  assert {
    condition     = length(aws_security_group.mcd_agent_vpc_sg) == 1
    error_message = "Module security group must still exist, so switching an existing agent never deletes it while in use."
  }
  assert {
    condition     = one(aws_lambda_function.mcd_agent_service_with_remote_upgrade_support[0].vpc_config).security_group_ids == toset(["sg-restricted-egress"])
    error_message = "Agent must use only the provided security groups."
  }
}
