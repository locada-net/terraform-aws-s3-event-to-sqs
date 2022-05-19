#(Optional) Create Producer IAM User
module "iam_user_uploader" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 4"

  name          = "s3.uploader"
  force_destroy = true

  password_reset_required = false

  create_iam_user_login_profile = false
  create_iam_access_key         = true
}

data "aws_iam_policy_document" "s3_uploader" {

  # Grant permission to upload file to S3
  statement {
    actions = [
      "s3:PutObject",
    ]

    resources = ["${aws_s3_bucket.bucket.arn}/*"]
  }
}

module "iam_group_uploader" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "~> 4"

  name = "uploader_s3"

  group_users = [
    module.iam_user_uploader.iam_user_name
  ]

  attach_iam_self_management_policy = false

  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
  ]

  custom_group_policies = [
    {
      name   = "AllowS3Upload"
      policy = data.aws_iam_policy_document.s3_uploader.json
    }
  ]
}