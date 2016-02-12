require 'protobuf/generators/base'
require 'protobuf/generators/option_generator'

module Protobuf
  module Generators
    class ServiceGenerator < Base

      def compile
        run_once(:compile) do
          print_class(descriptor.name, :service) do
            puts OptionGenerator.new(descriptor.options, 0).to_s if descriptor.options
            descriptor.method.each do |method_descriptor|
              print_method(method_descriptor)
            end
          end
        end
      end

      private

      def print_method(method_descriptor)
        name = method_descriptor.name
        request_klass = modulize(method_descriptor.input_type)
        response_klass = modulize(method_descriptor.output_type)
        options = {}
        if method_descriptor.options
          method_descriptor.options.each_field do |field_option|
            next unless field_option.extension?
            default_option_value = method_descriptor.options[field_option.name]
            next if default_option_value == field_option.default_value
            options[field_option.name] = serialize_value(default_option_value)
          end
        end

        rpc = "rpc :#{name.underscore}, #{request_klass}, #{response_klass}"

        if options.empty?
          puts rpc
          return
        end

        puts rpc + " do"
        options.each do |option_name, value|
          indent { puts "set_option #{option_name.inspect}, #{value}" }
        end
        puts "end"
      end

    end
  end
end
