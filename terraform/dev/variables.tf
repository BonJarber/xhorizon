# COMMON VARIABLES BETWEEN ALL ENVIRONMENTS

variable "common_s3_actions" {
  default = ["s3:PutObject", "s3:GetObject", "s3:PutObjectAcl", "s3:GetObjectAcl", "s3:ListBucket", "s3:DeleteObject"]
}

locals {
  bucket_names = ["profile-pictures", "job-results", "screenshots", "http-responses"]
}

variable "task_policy_name" {
  default = "default-task-policy"
}

variable "jobs_sg_name" {
  default = "default-task-policy"
}

variable "s3_access_policy_name" {
  default = "s3-access-policy"
}

variable "attach_s3_access_main_sa_name" {
  default = "attach-s3_access-main_sa"
}

# These need to be set using environment variables like so:

# export TF_VAR_jobs_user_secret="example"
variable "jobs_user_secret" {}

# export TF_VAR_jobs_pass_secret="example"
variable "jobs_pass_secret" {}


# DEV ENVIRONMENT SPECIFIC VARIABLES
variable "env" {
  default = "dev"
}