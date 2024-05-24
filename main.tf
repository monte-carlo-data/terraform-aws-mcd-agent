locals {
  # Wrapper metadata
  mcd_wrapper_version       = "0.1.5"
  mcd_agent_platform        = "AWS"
  mcd_agent_service_name    = "REMOTE_AGENT"
  mcd_agent_deployment_type = "TERRAFORM"

  # Deployment properties
  account_id                  = data.aws_caller_identity.current.account_id
  partition_id                = data.aws_partition.current.id
  connect_to_vpc              = length(var.private_subnets) >= 2 ? true : false
  skip_cloud_account_policy   = contains(["N/A", "590183797493"], var.cloud_account_id)
  invocation_role_source_arns = local.skip_cloud_account_policy ? ["arn:aws:iam::590183797493:root"] : ["arn:aws:iam::${var.cloud_account_id}:root", "arn:aws:iam::590183797493:root"]

  # Data store properties
  mcd_agent_store_name        = "mcd-agent-store-${random_id.mcd_agent_id.hex}"
  mcd_agent_store_data_prefix = "mcd/"

  # Lambda properties
  mcd_agent_function_name          = "mcd-agent-service-${random_id.mcd_agent_id.hex}"
  mcd_agent_function_image_account = element(split(".", var.image), 0)
  mcd_agent_function_image_uri     = replace(var.image, "*", var.region)
  mcd_agent_function_handler       = "apollo.interfaces.lambda_function.handler.lambda_handler"
  mcd_agent_function_memory        = 512
  mcd_agent_function_concurrency   = 42
  mcd_agent_function_timeout       = 900
  mcd_agent_function_package_type  = "Image"
  mcd_agent_function_environment_config = {
    MCD_AGENT_IMAGE_TAG      = local.mcd_agent_function_image_uri
    MCD_AGENT_CLOUD_PLATFORM = local.mcd_agent_platform
    MCD_STORAGE_BUCKET_NAME : aws_s3_bucket.mcd_agent_store.id
    MCD_AGENT_IS_REMOTE_UPGRADABLE : var.remote_upgradable ? "true" : "false"
    MCD_AGENT_WRAPPER_TYPE : local.mcd_agent_deployment_type
    MCD_AGENT_WRAPPER_VERSION : local.mcd_wrapper_version
    MCD_AGENT_CONNECTED_TO_A_VPC : local.connect_to_vpc ? "true" : "false"
    MCD_LOG_GROUP_ID : "arn:aws:logs:${var.region}:${local.account_id}:log-group:${aws_cloudwatch_log_group.mcd_agent_log_group.name}"
  }
}

resource "random_id" "mcd_agent_id" {
  byte_length = 4
}

data "aws_subnet" "first_subnet" {
  count = local.connect_to_vpc ? 1 : 0
  id    = var.private_subnets[0]
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

## ---------------------------------------------------------------------------------------------------------------------
## Agent Resources
## MCD agent core components: AWS Lambda for service execution and S3 for troubleshooting and temporary data.
## See details here: https://docs.getmontecarlo.com/docs/platform-architecture#customer-hosted-agent--object-storage-deployment
## ---------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "mcd_agent_store" {
  bucket = local.mcd_agent_store_name
}

resource "aws_s3_bucket_lifecycle_configuration" "mcd_agent_store_lifecycle" {
  bucket = aws_s3_bucket.mcd_agent_store.id
  rule {
    id = "${local.mcd_agent_store_name}-obj-expiration"
    expiration {
      days = 90
    }
    filter {
      prefix = local.mcd_agent_store_data_prefix
    }
    status = "Enabled"
  }
  rule {
    id = "${local.mcd_agent_store_name}-tmp-expiration"
    expiration {
      days = 2
    }
    filter {
      prefix = "${local.mcd_agent_store_data_prefix}tmp"
    }
    status = "Enabled"
  }
  rule {
    id = "${local.mcd_agent_store_name}-response-expiration"
    expiration {
      days = 1
    }
    filter {
      prefix = "${local.mcd_agent_store_data_prefix}responses"
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_cors_configuration" "mcd_agent_store_cors" {
  bucket = aws_s3_bucket.mcd_agent_store.id

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["https://getmontecarlo.com", "https://*.getmontecarlo.com"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_public_access_block" "mcd_agent_store_block_public_access" {
  bucket                  = aws_s3_bucket.mcd_agent_store.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mcd_agent_store_encryption" {
  bucket = aws_s3_bucket.mcd_agent_store.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "mcd_agent_store_ssl_policy" {
  bucket = aws_s3_bucket.mcd_agent_store.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "DenyActionsWithoutSSL",
        "Effect" : "Deny",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : "*",
        "Resource" : [
          aws_s3_bucket.mcd_agent_store.arn,
          "${aws_s3_bucket.mcd_agent_store.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "mcd_agent_log_group" {
  name              = "/aws/lambda/${local.mcd_agent_function_name}"
  retention_in_days = 14
}

resource "aws_lambda_function" "mcd_agent_service" {
  count = var.remote_upgradable ? 0 : 1
  depends_on = [
    aws_cloudwatch_log_group.mcd_agent_log_group
  ]
  function_name = local.mcd_agent_function_name
  role          = aws_iam_role.mcd_agent_service_execution_role.arn
  environment {
    variables = local.mcd_agent_function_environment_config
  }
  image_config {
    command = [
      local.mcd_agent_function_handler
    ]
  }
  image_uri                      = local.mcd_agent_function_image_uri
  memory_size                    = local.mcd_agent_function_memory
  package_type                   = local.mcd_agent_function_package_type
  reserved_concurrent_executions = local.mcd_agent_function_concurrency
  timeout                        = local.mcd_agent_function_timeout
  dynamic "vpc_config" {
    for_each = local.connect_to_vpc ? [1] : []
    content {
      security_group_ids = [aws_security_group.mcd_agent_vpc_sg[0].id]
      subnet_ids         = var.private_subnets
    }
  }
}

# Terraform lifecycle meta arguments do not support conditions so two copies of the resource are required to ignore
# remote (agent sourced) image upgrades.
resource "aws_lambda_function" "mcd_agent_service_with_remote_upgrade_support" {
  count = var.remote_upgradable ? 1 : 0
  depends_on = [
    aws_cloudwatch_log_group.mcd_agent_log_group
  ]
  function_name = local.mcd_agent_function_name
  role          = aws_iam_role.mcd_agent_service_execution_role.arn
  environment {
    variables = local.mcd_agent_function_environment_config
  }
  image_config {
    command = [
      local.mcd_agent_function_handler
    ]
  }
  image_uri                      = local.mcd_agent_function_image_uri
  memory_size                    = local.mcd_agent_function_memory
  package_type                   = local.mcd_agent_function_package_type
  reserved_concurrent_executions = local.mcd_agent_function_concurrency
  timeout                        = local.mcd_agent_function_timeout
  dynamic "vpc_config" {
    for_each = local.connect_to_vpc ? [1] : []
    content {
      security_group_ids = [aws_security_group.mcd_agent_vpc_sg[0].id]
      subnet_ids         = var.private_subnets
    }
  }
  lifecycle {
    ignore_changes = [
      image_uri,
      memory_size,
      reserved_concurrent_executions
    ]
  }
}

resource "aws_iam_role" "mcd_agent_service_execution_role" {
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Action" : "sts:AssumeRole"
        "Effect" : "Allow"
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        }
      }
    ]
  })
  managed_policy_arns = [
    local.connect_to_vpc ? "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole" : "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
  name_prefix = "mcd_agent_service_execution_role"
  tags = {
    RoleSource = "monte-carlo-agent"
  }
}

resource "aws_iam_role_policy" "mcd_agent_service_s3_policy" {
  name = "s3_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketPolicyStatus",
          "s3:GetBucketAcl"
        ],
        "Resource" : [
          aws_s3_bucket.mcd_agent_store.arn,
          "${aws_s3_bucket.mcd_agent_store.arn}/*"
        ],
        "Effect" : "Allow"
      }
    ]
  })
  role = aws_iam_role.mcd_agent_service_execution_role.id
}

resource "aws_iam_role_policy" "mcd_agent_service_lambda_logs_policy" {
  name = "lambda_logs_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "logs:Describe*",
          "logs:Get*",
          "logs:List*",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:FilterLogEvents"
        ],
        "Resource" : [
          "${local.mcd_agent_function_environment_config.MCD_LOG_GROUP_ID}:*"
        ],
        "Effect" : "Allow"
      }
    ]
    }
  )
  role = aws_iam_role.mcd_agent_service_execution_role.id
}

resource "aws_iam_role_policy" "mcd_agent_service_lambda_stop_query_policy" {
  name = "lambda_stop_query_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "logs:StopQuery"
        ],
        "Resource" : [
          "arn:aws:logs:${var.region}:${local.account_id}:log-group:*"
        ],
        "Effect" : "Allow"
      }
    ]
  })
  role = aws_iam_role.mcd_agent_service_execution_role.id
}

resource "aws_iam_role_policy" "mcd_agent_service_lambda_update_policy" {
  count = var.remote_upgradable ? 1 : 0
  name  = "lambda_update_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "lambda:CreateFunction",
          "lambda:UpdateFunctionCode",
          "lambda:TagResource",
          "lambda:UntagResource",
          "lambda:UpdateFunctionConfiguration",
          "lambda:DeleteFunction",
          "lambda:DeleteFunctionConcurrency",
          "lambda:PutFunctionConcurrency"
        ],
        "Resource" : [
          "arn:aws:lambda:${var.region}:${local.account_id}:function:${local.mcd_agent_function_name}"
        ],
        "Effect" : "Allow"
      }
    ]
  })
  role = aws_iam_role.mcd_agent_service_execution_role.id
}

resource "aws_iam_role_policy" "mcd_agent_service_lambda_info_policy" {
  name = "lambda_info_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "lambda:GetFunctionConfiguration",
          "lambda:ListTags",
          "lambda:GetFunction"
        ],
        "Resource" : [
          "arn:aws:lambda:${var.region}:${local.account_id}:function:${local.mcd_agent_function_name}"
        ],
        "Effect" : "Allow"
      }
    ]
  })
  role = aws_iam_role.mcd_agent_service_execution_role.id
}

resource "aws_iam_role_policy" "mcd_agent_service_assume_role_policy" {
  name = "assume_role_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "sts:AssumeRole"
        ],
        "Condition" : {
          "StringEquals" : {
            "iam:ResourceTag/MonteCarloData" : ""
          }
        },
        "Resource" : [
          "*"
        ],
        "Effect" : "Allow"
      }
    ]
  })
  role = aws_iam_role.mcd_agent_service_execution_role.id
}

resource "aws_iam_role_policy" "mcd_agent_service_repo_policy" {
  count = var.remote_upgradable ? 1 : 0
  name  = "repo_access_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ],
        "Resource" : [
          "arn:aws:ecr:${var.region}:${local.mcd_agent_function_image_account}:repository/*"
        ],
        "Effect" : "Allow"
      }
    ]
  })
  role = aws_iam_role.mcd_agent_service_execution_role.id
}

resource "aws_security_group" "mcd_agent_vpc_sg" {
  count = local.connect_to_vpc ? 1 : 0
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = -1
    self      = true
  }
  name_prefix = "mcd_agent_vpc_sg"
  vpc_id      = data.aws_subnet.first_subnet[0].vpc_id
}

## ---------------------------------------------------------------------------------------------------------------------
## Invoker Resources
## MCD agent invoker role. Allows Monte Carlo to submit requests to this agent.
## ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "mcd_agent_service_invocation_role" {
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : local.invocation_role_source_arns
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {
          "StringEquals" : {
            "sts:ExternalId" : random_id.mcd_agent_id.hex
          }
        }
      }
    ]
  })
  inline_policy {
    name = "invoke_policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "lambda:InvokeFunction"
          ],
          "Resource" : [
            var.remote_upgradable ?
            aws_lambda_function.mcd_agent_service_with_remote_upgrade_support[0].arn : aws_lambda_function.mcd_agent_service[0].arn
          ],
          "Effect" : "Allow"
        }
      ]
    })
  }
  name_prefix = "mcd_agent_service_invocation_role"
  tags = {
    MonteCarloData = ""
  }
}
