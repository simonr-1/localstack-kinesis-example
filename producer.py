import json
import boto3
from botocore import exceptions
from botocore.config import Config
import time

config = Config(
    connect_timeout = 5,
    read_timeout = 5,
    retries = {
      'max_attempts': 1,
      'mode': 'standard'
   }
)

kinesis = boto3.client("kinesis", endpoint_url="http://localhost:4566", config=config)
stream_name = "kinesis_test"

try:
  response = kinesis.put_record(
      StreamName=stream_name,
      Data=json.dumps({
          'example': 'payload',
          'hello': 'world'
      }),
      PartitionKey="0"
  )

  print(response)
except exceptions.ReadTimeoutError as error:
  raise Exception("Client error occured: {}".format(error)) from None
  
