import boto3
import time
import logging
import os
logger = logging.getLogger()
logger.setLevel(logging.INFO)


dynamodb = boto3.resource('dynamodb', endpoint_url="http://{}:4566".format(os.environ['LOCALSTACK_HOSTNAME'])) 
table_name = 'test'
def lambda_handler(event, context):
  logger.debug("Starting lambda {}".format(time.time() * 1000))
  table = dynamodb.Table(table_name)
  for i in range(1,1000):
    item = {
      'id': i,
      'timestamp': round(time.time() * 1000)
    }
    response = table.put_item(Item=item)
    if( response['ResponseMetadata'] and response['ResponseMetadata']['HTTPStatusCode'] == 200 ):
      logger.info('Added id: {} to test table'.format(i))
    else:
      logger.debug('There was a problem adding id {} to the table'.format(i))
  logger.debug("Finished lambda {}".format(time.time() * 1000))
  return True
