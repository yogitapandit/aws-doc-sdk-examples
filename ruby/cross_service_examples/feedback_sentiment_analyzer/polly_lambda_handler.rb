require 'json'
require 'aws-sdk-polly'
require 'aws-sdk-s3'
require 'logger'
# require 'pry'

def lambda_handler(event:, context:)

  logger = Logger.new($stdout)

  logger.info("event:\n #{event}")
  logger.info("context:\n #{context}")

  # Create an instance of the Textract client
  polly_client = Aws::Polly::Client.new(region: "us-east-1")


  resp = polly_client.synthesize_speech({
                                          output_format: "mp3",
                                          text: event['translated_text']['Payload']['translated_text'],
                                          voice_id: "Joanna",
                                        })

  logger.info(resp.to_s)

  # Define the bucket name and file name for the MP3 file in S3
  bucket_name = event['detail']['bucket']['name']
  comment_key = event['detail']['object']['key']
  prefix = comment_key.split('/')[0]

  key = "#{prefix}/recording.mp3"

  s3_client = Aws::S3::Client.new(region: "us-east-1")

  # Put the MP3 file to S3
  s3_client.put_object(
    bucket: bucket_name,
    key: key, # Use a unique key for the file
    body: resp.audio_stream
  )

  logger.info("Key: #{key}")

  key
end
