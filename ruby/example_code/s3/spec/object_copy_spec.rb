# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

require "rspec"
require_relative "../object_copy"

describe ObjectCopyWrapper do
  let(:source_object) { Aws::S3::Object.new("spec-source-bucket", "spec-source-key", stub_responses: true) }
  let(:target_bucket) { Aws::S3::Bucket.new("spec-target-bucket", stub_responses: true) }
  let(:wrapper) { ObjectCopyWrapper.new(source_object) }

  it "confirms the object was copied" do
    source_object.client.stub_responses(:copy_object)
    target_obj = wrapper.copy_object(target_bucket, "spec-target-key")
    expect(target_obj.key).to be_eql("spec-target-key")
  end

  it "confirms error is caught when object can't be copied" do
    source_object.client.stub_responses(:copy_object, "TestError")
    expect(wrapper.copy_object(target_bucket, "spec-target-key")).to be_nil
  end
end
