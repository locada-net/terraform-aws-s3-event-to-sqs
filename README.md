# 1. Launch Terraform CLI Docker

	docker run -it --rm -v "$(pwd):/home/workspace" -w /home/workspace --entrypoint sh hashicorp/terraform:1.1.9

# 2. Create Infrastructure

Configure your AWS Access (within container)

	export AWS_ACCESS_KEY_ID="YOUR_SECRET_KEY_ID"
	export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"
	export AWS_DEFAULT_REGION="us-east-1"
	
Lets create the infrastructure (within container)

	terraform init
	terraform apply

# 4. Get S3 Bucket name and SQS Endpoint

Lets get the S3 Bucket Name & SQS Endpoint from Terraform Output, to use it later.

	terraform output -raw s3_bucket_name 
	terraform output -raw sqs_https_endpoint

# 5. Test - Uploader User

	docker run --rm -it --entrypoint sh amazon/aws-cli:2.7.0
	aws configure

	echo "Just a dummy content for text file" > object_to_upload.txt
	aws s3 cp "$(pwd)/object_to_upload.txt" s3://S3_BUCKET_NAME/

# 6. Test - Consumer User

	docker run --rm -it --entrypoint sh amazon/aws-cli:2.7.0
	aws configure
	aws sqs receive-message --queue-url SQS_HTTPS_ENDPOINT --attribute-names All --message-attribute-names All