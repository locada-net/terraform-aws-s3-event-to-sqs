module "iam_user_consumer" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "~> 4"

  name          = "sqs.consumer"
  force_destroy = true

  password_reset_required = false

  create_iam_user_login_profile = false
  create_iam_access_key         = true
}

data "aws_iam_policy_document" "consumer" {

  #Grant permission to Consumer to Read Message from SQS
  statement {
    actions = [
      "sqs:ReceiveMessage",
    ]

    resources = [aws_sqs_queue.queue.arn]
  }

  #Grant permission to Consumer to Decrypt Message from SQS
  statement {
    actions = [
      "kms:Decrypt"
    ]

    resources = [aws_kms_key.cmk.arn]
  }
}

module "iam_group_consumer" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "~> 4"

  name = "consumer_sqs"

  group_users = [
    module.iam_user_consumer.iam_user_name
  ]

  attach_iam_self_management_policy = false

  # In a perfect world, we would restrict the access only to required S3.
  custom_group_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
  ]

  custom_group_policies = [
    {
      name   = "AllowSQSKMS"
      policy = data.aws_iam_policy_document.consumer.json
    }
  ]
}
