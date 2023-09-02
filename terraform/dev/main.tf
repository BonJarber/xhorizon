terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

# output "version_content" {
#   value = file("../../${path.module}/jobs/example/VERSION")
# }

module "iam" {
  source = "../modules/iam"
  env = var.env
  common_s3_actions = var.common_s3_actions
  buckets = [for name in local.bucket_names : "${name}-${var.env}-xhorizon"]
  jobs_sg_name = "${var.env}-${var.jobs_sg_name}"
  task_policy_name = "${var.env}-${var.task_policy_name}"
  jobs_user_secret = var.jobs_user_secret
  jobs_pass_secret = var.jobs_pass_secret
}

module "s3" {
  source = "../modules/s3"
  main_sa = module.iam.main_sa
  common_s3_actions = var.common_s3_actions
  buckets = [for name in local.bucket_names : "${name}-${var.env}-xhorizon"]
  s3_access_policy_name = "${var.env}-${var.s3_access_policy_name}"
  attach_s3_access_main_sa_name = "${var.env}-${var.attach_s3_access_main_sa_name}"
}