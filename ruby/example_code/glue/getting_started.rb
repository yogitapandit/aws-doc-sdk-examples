# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# To run this demo, you will need Ruby 2.6 or later, plus dependencies.
# For more information, see:
# https://github.com/awsdocs/aws-doc-sdk-examples/blob/main/ruby/README.md

require 'aws-sdk-glue'
require 'aws-sdk-iam'
require 'aws-sdk-s3'
require 'io/console'
require 'pp'
require 'logger'
require 'optparse'
require 'cli/ui'
require 'yaml'
require 'pry'
require_relative("../../helpers/disclaimers")
require_relative("../../helpers/decorators")
require_relative("../../helpers/waiters")
require_relative('glue_wrapper')

@logger = Logger.new($stdout)
@logger.level = Logger::WARN

# snippet-start:[ruby.example_code.glue.Scenario_GetStartedCrawlersJobs]
class GlueCrawlerJobScenario
  def initialize(glue_client, glue_service_role, glue_bucket)
    @glue_client = glue_client
    @glue_service_role = glue_service_role
    @glue_bucket = glue_bucket
  end

  def run(crawler_name, db_name, db_prefix, data_source, job_script, job_name)
    wrapper = GlueWrapper.new(@glue_client)

    # Explain that script has been uploaded.
    # The script essentially reads flight data from a table,
    # performs some transformations and simplifications,
    # and writes the transformed data to an S3 bucket.

    new_step(1, "Create a crawler")
    puts "Checking for crawler #{crawler_name}."
    crawler = wrapper.get_crawler(crawler_name)
    if crawler.nil?
      puts "Creating crawler #{crawler_name}."
      wrapper.create_crawler(crawler_name, @glue_service_role.arn, db_name, db_prefix, data_source)
      puts "Successfully created #{crawler_name}:"
      crawler = wrapper.get_crawler(crawler_name)
      puts JSON.pretty_generate(crawler).yellow
    end
    print "\nDone!\n".green

    new_step(2, "Run a crawler to output a database")
    puts "When you run the crawler, it crawls data stored in #{data_source} and creates a metadata database in the AWS Glue Data Catalog that describes the data in the data source."
    puts "In this example, the source data is in CSV format."
    wrapper.start_crawler(crawler_name)
    puts "Let's wait for the crawler to run. This typically takes a few minutes."
    crawler_state = nil
    while crawler_state != 'READY'
      custom_wait(30)
      crawler = wrapper.get_crawler(crawler_name)
      crawler_state = crawler['state']
      print "Status check: #{crawler['state']}.".yellow
    end
    print "\nDone!\n".green

    new_step(3, "Query the database")
    database = wrapper.get_database(db_name)
    puts "The crawler created database #{db_name}:"
    print "#{database}".yellow
    puts "\nThe database contains these tables:"
    tables = wrapper.get_tables(db_name)
    tables.each_with_index do |table, index|
      print "\t#{index + 1}. #{table['name']}".yellow
    end
    print "\nDone!\n".green
    puts '-' * 88

    new_step(4, "Create a job definition that runs an ETL script")
    puts "Uploading Python ETL script to S3..."
    wrapper.upload_job_script(job_script, @glue_bucket)
    puts "Creating job definition #{job_name}:\n"
    response = wrapper.create_job(job_name, 'Getting started example job.', @glue_service_role.arn, "s3://#{@glue_bucket.name}/#{job_script}")
    puts JSON.pretty_generate(response).yellow
    print "\nDone!\n".green


    # puts "When you run the job, it extracts data from #{data_source}, transforms it " \
    #  "by using the #{job_script} script, and loads the output into " \
    #  "S3 bucket #{self.glue_bucket.name}."
    # puts "In this example, the data is transformed from CSV to JSON, and only a few " \
    #  "fields are included in the output."

    new_step(5, "Start a new job")
    job_run_status = nil
    job_run_id = wrapper.start_job_run(
      job_name,
      db_name,
      tables[0]['name'],
      @glue_bucket.name
    )
    puts "Job #{job_name} started. Let's wait for it to run."
    until ['SUCCEEDED', 'STOPPED', 'FAILED', 'TIMEOUT'].include?(job_run_status)
      custom_wait(10)
      job_run = wrapper.get_job_runs(job_name)
      job_run_status = job_run[0]['job_run_state']
      print "Status check: #{job_name}/#{job_run_id} - #{job_run_status}.".yellow
    end
    puts '-' * 88

    new_step(6, "View results from a successful job run")
    if job_run_status == 'SUCCEEDED'
      puts "Data from your job run is stored in your S3 bucket '#{@glue_bucket.name}'. Files include:"
      begin

        # Print the key name of each object in the bucket.
        @glue_bucket.objects.each do |object_summary|
          if object_summary.key.include?('run-')
            print "#{object_summary.key}".yellow
          end
        end

        # Print the first 256 bytes of a run file
        desired_sample_objects = 1
        @glue_bucket.objects.each do |object_summary|
          if object_summary.key.include?('run-')
            if desired_sample_objects > 0
              sample_object = @glue_bucket.object(object_summary.key)
              sample = sample_object.get(range: 'bytes=0-255').body.read
              puts "\nSample run file contents:"
              print "#{sample}".yellow
              desired_sample_objects -= 1
            end
          end
        end
      rescue Aws::S3::Errors::ServiceError => e
        logger.error(
          "Couldn't get job run data. Here's why: %s: %s",
          e.response.error.code, e.response.error.message
        )
        raise
      end
    end

    puts '-' * 88

  end

end
def main

  banner('../../helpers/banner.txt')
  puts "######################################################################################################".yellow
  puts "#                                                                                                    #".yellow
  puts "#                                          EXAMPLE CODE DEMO:                                        #".yellow
  puts "#                                              AWS Glue                                              #".yellow
  puts "#                                                                                                    #".yellow
  puts "######################################################################################################".yellow
  puts ""
  puts "You have launched a demo of AWS Glue using the AWS for Ruby v3 SDK. Over the next 60 seconds, it will"
  puts "do the following:"
  puts "    1. Create a basic IAM role and policy for Lambda invocation."
  puts "    2. Create a new Lambda function."
  puts "    3. Invoke the Lambda function."
  puts "    4. Update the Lambda function code."
  puts "    5. Update the Lambda function configuration."
  puts "    6. Destroy the Lambda function and associated IAM role."
  puts ""

  confirm_begin
  billing
  security
  puts "\e[H\e[2J"

  # Set input file names
  job_script_filepath = 'job_script.py'
  resource_names = YAML.load_file('resource_names.yaml')

  # Instantiate existing IAM role.
  iam = Aws::IAM::Resource.new(region: 'us-east-1')
  iam_role_name = resource_names['glue_service_role']
  iam_role = iam.role(iam_role_name)

  # Instantiate existing S3 bucket.
  s3 = Aws::S3::Resource.new(region: 'us-east-1')
  s3_bucket_name = resource_names['glue_bucket']
  s3_bucket = s3.bucket(s3_bucket_name)

  scenario = GlueCrawlerJobScenario.new(
    Aws::Glue::Client.new(region: 'us-east-1'),
    iam_role,
    s3_bucket
  )

  random_int = rand(10 ** 4)
  scenario.run(
    "doc-example-crawler-#{random_int}",
    "doc-example-database-#{random_int}",
    "doc-example-#{random_int}-",
    's3://crawler-public-us-east-1/flight/2016/csv',
    job_script_filepath,
    "doc-example-job-#{random_int}"
  )

  puts '-' * 88
  puts "To destroy scaffold resources, run cdk destroy'."
  puts "\nThanks for watching!"
  puts '-' * 88
# rescue Exception => e
#   @logger.error("Something went wrong with the example:\n #{e}")
end

if __FILE__ == $0
  main
end