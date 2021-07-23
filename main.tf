variable "aws_region" {
  default = "eu-west-2"
}

provider "aws" {
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    s3_force_path_style         = true
    access_key                  = "test"
    secret_key                  = "test" 
    region                      = var.aws_region

    endpoints {
        cloudwatch   = "http://localhost:4566"
        dynamodb     = "http://localhost:4566"
        lambda       = "http://localhost:4566"
        kinesis      = "http://localhost:4566"
        iam          = "http://localhost:4566"
        sts          = "http://localhost:4566"
    }
}



#
# Kinesis streams
#
resource "aws_kinesis_stream" "kinesis_test" {
  name             = "kinesis_test"
  shard_count      = 1
  retention_period = 24

  tags = {
    Environment = "test"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF  
  lifecycle {
    create_before_destroy = true
  }
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}


resource "aws_iam_policy" "lambda_kinesis" {
  name = "lambda_kinesis"
  policy = <<EOF
{  
  "Version": "2012-10-17",
  "Statement":[
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "kinesis:GetRecords",
        "kinesis:GetShardIterator",
        "kinesis:DescribeStream",
        "kinesis:ListStreams",
        "kinesis:ListShards"
      ],
      "Resource": "arn:aws:kinesis:*:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "lambda_kinesis" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_kinesis.arn
}


# TODO: how is the APP_VERSION picked up here
resource "aws_lambda_function" "test" {
  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda.zip"))}"
  source_code_hash = filebase64sha256("lambda.zip")
  filename      = "lambda.zip"
  function_name = "test"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda.lambda_handler"

  
  runtime = "python3.8"
  memory_size   = 256
  timeout       = 900
 
  environment {
    variables = {
      AWS_LAMBDA_ROLE = aws_iam_role.lambda_role.arn
      AWS_DEFAULT_REGION=var.aws_region
    }
  }
}

# Trigger mapping
resource "aws_lambda_event_source_mapping" "lambda_mapping" {
  event_source_arn  = aws_kinesis_stream.kinesis_test.arn
  function_name     = aws_lambda_function.test.arn
  starting_position = "LATEST"
  maximum_retry_attempts = 0
  parallelization_factor = 1
}


#
## Dynamo db tables
#
resource "aws_dynamodb_table" "test" {
  name      = "test"
  hash_key  = "id"
  billing_mode     = "PAY_PER_REQUEST"
  attribute {
    name = "id"
    type = "N"
  }

}

