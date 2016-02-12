# encoding: binary

require 'spec_helper'
require 'protobuf/code_generator'

RSpec.describe 'code generation' do
  it "generates code for google's unittest.proto" do
    bytes = IO.read(PROTOS_PATH.join('google_unittest.bin'), mode: 'rb')

    expected_files =
      ["google_unittest_import_public.pb.rb", "google_unittest_import.pb.rb", "google_unittest.pb.rb"]

    expected_file_descriptors = expected_files.map do |file_name|
      file_content = File.open(PROTOS_PATH.join(file_name), "r:UTF-8", &:read)
      ::Google::Protobuf::Compiler::CodeGeneratorResponse::File.new(
        :name => "protos/" + file_name, :content => file_content)
    end

    expected_output =
      ::Google::Protobuf::Compiler::CodeGeneratorResponse.encode(:file => expected_file_descriptors)

    code_generator = ::Protobuf::CodeGenerator.new(bytes)
    code_generator.eval_unknown_extensions!
    expect(code_generator.response_bytes).to eq(expected_output)
  end

  it "generates code (including service stubs) with custom field and method options" do
    bytes = IO.read(PROTOS_PATH.join('google_unittest_custom_options.bin'), mode: 'rb')
    descriptor =
      File.expand_path("../../../lib/protobuf/descriptors/google/protobuf/descriptor.pb.rb", __FILE__)
    expected_descriptor = IO.read(descriptor, mode: 'rb')
    expected_unittest_custom_options =
      File.open(PROTOS_PATH.join('google_unittest_custom_options.pb.rb'), "r:UTF-8", &:read)

    expected_files_and_contents = {
      'google/protobuf/descriptor.pb.rb': expected_descriptor,
      'protos/google_unittest_custom_options.pb.rb': expected_unittest_custom_options
    }
    expected_file_descriptors = expected_files_and_contents.map do |file_name, file_content|
      ::Google::Protobuf::Compiler::CodeGeneratorResponse::File.new(:name => file_name, :content => file_content)
    end
    expected_output = ::Google::Protobuf::Compiler::CodeGeneratorResponse.encode(:file => expected_file_descriptors)

    code_generator = ::Protobuf::CodeGenerator.new(bytes)
    code_generator.eval_unknown_extensions!
    expect(code_generator.response_bytes).to eq(expected_output)
  end
end
