output "s3_bucket_name" {
    description = "Bucket name"
    value = aws_s3_bucket.bucket.bucket
}
output "sqs_https_endpoint" {
    description = "SQS HTTPS Endpoint"
    value = aws_sqs_queue.queue.url
}

# Credentials for the uploader system
output "iam_uploader_access_key_id" {
    value = module.iam_user_uploader.iam_access_key_id
}
output "iam_uploaderr_access_key_secret" {
    value = module.iam_user_uploader.iam_access_key_secret
    sensitive = true
}

# Credentials for the consumer system
output "iam_consumer_access_key_id" {
    value = module.iam_user_consumer.iam_access_key_id
}
output "iam_consumer_access_key_secret" {
    value = module.iam_user_consumer.iam_access_key_secret
    sensitive = true
}