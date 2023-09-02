data "aws_caller_identity" "current" {}
# ---- Create IAM Users ---- #

# Main Service Account 
resource "aws_iam_user" "main_sa" {
  name = var.main_service_account
}

# Create access key to be stored in service
resource "aws_iam_access_key" "main_sa_key" {
  user    = aws_iam_user.main_sa.name
}

# Github Actions Service Account
resource "aws_iam_user" "gh_sa" {
  name = var.github_service_account
}

# Create access key to be stored in github
resource "aws_iam_access_key" "gh_sa_key" {
  user    = aws_iam_user.gh_sa.name
}

# ---- Define Policies ---- #

# Policy to allow access to ECR
resource "aws_iam_policy" "ecr_push_policy" {
  name        = "ecr_push_policy"
  description = "Provides access to push images to ECR"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetAuthorizationToken",
        "ecr:PutLifecyclePolicy",
        "ecr:PutImageTagMutability",
        "ecr:StartImageScan",
        "ecr:CreateRepository",
        "ecr:PutImageScanningConfiguration",
        "ecr:CompleteLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:StartLifecyclePolicyPreview",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# ESC Task Run Policy
resource "aws_iam_policy" "ecs_run_task_policy" {
  name        = "ecs_run_task_policy"
  description = "Provides access to run ECS tasks"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecs:RunTask",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "kms:Decrypt"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# Pass role policy
resource "aws_iam_policy" "pass_role_policy" {
  name        = "pass_role_policy"
  description = "Allow pass role"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "iam:PassRole"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*" 
    }
  ]
}
EOF
}

# ---- Define Roles ---- #

# ECS Task Execution Role
resource "aws_iam_role" "ecs_role" {
  name = "ecs_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


# ---- Attach Policies ---- #

# Attach policy to Github service account
resource "aws_iam_user_policy_attachment" "attach-gh_sa-to-ecr_push_policy" {
  user       = aws_iam_user.gh_sa.name
  policy_arn = aws_iam_policy.ecr_push_policy.arn
}

# Attach Task Execution Role Policy to Main Service Account
resource "aws_iam_user_policy_attachment" "attach-main_sa-to-AmazonECSTaskExecutionRolePolicy" {
  user       = aws_iam_user.main_sa.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach ECS Run Task Policy to Main Service Account
resource "aws_iam_user_policy_attachment" "attach-main_sa-to-ecs_run_task_policy" {
  user       = aws_iam_user.main_sa.name
  policy_arn = aws_iam_policy.ecs_run_task_policy.arn
}

# Attach Pass Role Policy to Main Service Account
resource "aws_iam_user_policy_attachment" "attach-main_sa-to-pass_role_policy" {
  user       = aws_iam_user.main_sa.name
  policy_arn = aws_iam_policy.pass_role_policy.arn
}

# ---- Secrets ---- #
# Declare the Secrets
resource "aws_secretsmanager_secret" "jobs_user_secret" {
  name = "jobs_user_secret"
}

resource "aws_secretsmanager_secret" "jobs_pass_secret" {
  name = "jobs_pass_secret"
}


resource "aws_secretsmanager_secret_version" "jobs_user_secret_version" {
  secret_id     = aws_secretsmanager_secret.jobs_user_secret.id
  secret_string = var.jobs_user_secret
}

resource "aws_secretsmanager_secret_version" "jobs_pass_secret_version" {
  secret_id     = aws_secretsmanager_secret.jobs_pass_secret.id
  secret_string = var.jobs_pass_secret
}


resource "aws_iam_policy" "default_task_policy" {
  name        = var.task_policy_name
  description = "Default policy for common task actions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = var.secrets_manager_actions,
        Resource = [
          aws_secretsmanager_secret_version.jobs_user_secret_version.arn,
          aws_secretsmanager_secret_version.jobs_pass_secret_version.arn,
        ]
      },
      {
        Effect = "Allow",
        Action = var.common_s3_actions,
        Resource = [for bucket in var.buckets : "arn:aws:s3:::${bucket}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_task_role_task_policy" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = aws_iam_policy.default_task_policy.arn
}

# ---- Networking ---- #

data "aws_vpc" "xhorizon_vpc" {
  tags = {
    Name = "copilot-xhorizon-${var.env}"
  }
}

resource "aws_security_group" "jobs_sg" {
  name        = var.jobs_sg_name
  description = "Security group jobs run in"
  vpc_id      = data.aws_vpc.xhorizon_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}