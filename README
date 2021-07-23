# Localstack kinesis issue

## Issue:
Their is an issue in the kinesis where it looks like if the kinesis stream is set to trigger a lambda function it only returns a response to the producer after the invoked lambda has finished running.

## Expected behaviour:
Kinesis should return a response to the client stating whether the request was successful/unsuccessful, there shouldn't be any delay or reliance on a lambda function completing 

## Actual behaviour:
Kinesis only returns a response after the invoked lambda has completed, this means aws sdks that have implemented retry mechanisms will attempt to send the data again.
Another effect is that lambda's end up running in parallel even though the parallelization_factor is set to 0


# Requirements:
--[Localstack](https://github.com/localstack/localstack) 
--[Terraform](https://www.terraform.io/downloads.html)

# Steps to reproduce
1. Start localstack by running the following command `SERVICES=kinesis,lambda,ec2,iam,dynamodb DEFAULT_REGION=eu-west-2 DEBUG=1 localstack start`
2. Create a lambda.zip file which contains the lambda.py file by running the command `zip lambda.zip lambda.py` the zip file should be in the same directory as the main.tf file
3. Run `terraform init`
4. Run `terraform apply -auto-approve` this will create the relevant terraform resources
5. Once all the resources have been created run the producer.py script
