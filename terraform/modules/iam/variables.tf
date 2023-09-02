variable "main_service_account" {
    default = "main-service-account"
}

variable "github_service_account" {
    default = "github-service-account"
}

variable "secrets_manager_actions" {
    default = [
          "secretsmanager:GetRandomPassword",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "ssm:GetParameters"
        ]
}

# Dynamic variables
variable "env" {}
variable "common_s3_actions" {}
variable "buckets" {}
variable "jobs_sg_name" {}
variable "task_policy_name" {}
variable "jobs_user_secret" {}
variable "jobs_pass_secret" {}