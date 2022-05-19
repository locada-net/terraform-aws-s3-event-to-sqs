# Useful for retrieving information about the logged-in aws account
data "aws_caller_identity" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

# Create Simple S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "locada-terraform-example-bucket"
  force_destroy = true
}

# Setup S3 with Private ACL
resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}

# Setup S3 Event Notification for uploaded file
# S3 Will send notification to SQS with information about the file just uploaded
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  queue {
    id            = "OnObjectUploaded"
    queue_arn     = aws_sqs_queue.queue.arn
    events        = ["s3:ObjectCreated:*"]
  }
}

# Create KMS CMK For encrypting/decrypting messages
# Grant S3 Permission to interact with KMS CMK
resource "aws_kms_key" "cmk" {
  description             = "KMS For Encrypt/Decrypt SQS Messages"
  deletion_window_in_days = 7 #Min 7
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "kms-policy",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${local.aws_account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow S3",
            "Effect": "Allow",
            "Principal": {
                "Service": "s3.amazonaws.com"
            },
            "Action": [
                "kms:GenerateDataKey",
                "kms:Decrypt"
            ],
            "Resource": "*"
        }
    ]
}
  POLICY
}

#Create SQS Queue (SSE-KMS) - Customer Managed Key
resource "aws_sqs_queue" "queue" {
  name                              = "locada-terraform-example-queue"
  kms_master_key_id                 = aws_kms_key.cmk.key_id
  kms_data_key_reuse_period_seconds = 300
}

#Grant permission to S3 to send Message to SQS
resource "aws_sqs_queue_policy" "s3_permission" {
  queue_url = aws_sqs_queue.queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "SQSPolicy",
  "Statement": [
    {
      "Sid": "AllowS3SendMessage",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_s3_bucket.bucket.arn}"
        }
      }
    }
  ]
}
POLICY
}