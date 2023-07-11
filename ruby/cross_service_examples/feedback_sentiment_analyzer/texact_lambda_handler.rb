# This is a Lambfa function using the Textract client making x y calls
# to the Textract API.








#
# require 'json'
# require 'aws-sdk-textract'
# require 'logger'
# # require 'pry'
#
# def lambda_handler(event:, context:)
#
#   logger = Logger.new($stdout)
#
#   logger.info("event:\n #{event.to_s}\n")
#   logger.info("context:\n #{context.to_s}\n")
#
#   # Create an instance of the Textract client
#   client = Aws::Textract::Client.new(region: "us-east-1")
#
#   response = client.detect_document_text({
#                                            document: {
#                                              s3_object: {
#                                                bucket: event['detail']['bucket']['name'],
#                                                name: event['detail']['object']['key']
#                                              }
#                                            },
#                                          })
#   logger.info("#{response.to_s}\n")
#
#   extracted_words = []
#
#
#   response.blocks.each do |obj|
#     if obj.block_type.include?('LINE')
#       if obj.respond_to?(:text) && obj.text
#         extracted_words.append(obj.text)
#       end
#     end
#   end
#
#   logger.info("extracted words: #{extracted_words.to_s}")
#
#   extracted_words.join(" ")
# end
