# ---- Create S3 Buckets ---- #
resource "aws_s3_bucket" "my_buckets" {
  for_each = toset(var.buckets)
  bucket = each.key
  acl = "private"
}

# ---- S3 Access Policy ---- #
resource "aws_iam_policy" "s3_access_policy" {
  name        = var.s3_access_policy_name
  description = "Policy to allow access to S3"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = var.common_s3_actions,
        Resource = [for bucket in var.buckets : "arn:aws:s3:::${bucket}/*"]
      }
    ]
  })
}

# ---- Attach S3 Access Policy to Main Service Account ---- #
resource "aws_iam_policy_attachment" "attach_s3_access_main_sa" {
  name       = var.attach_s3_access_main_sa_name
  users      = [var.main_sa.name]
  policy_arn = aws_iam_policy.s3_access_policy.arn
}