require 'protobuf/generators/base'

module Protobuf
  module Generators
    class FieldGenerator < Base

      ##
      # Constants
      #
      PROTO_INFINITY_DEFAULT          = /^inf$/i.freeze
      PROTO_NEGATIVE_INFINITY_DEFAULT = /^-inf$/i.freeze
      PROTO_NAN_DEFAULT               = /^nan$/i.freeze
      RUBY_INFINITY_DEFAULT           = '::Float::INFINITY'.freeze
      RUBY_NEGATIVE_INFINITY_DEFAULT  = '-::Float::INFINITY'.freeze
      RUBY_NAN_DEFAULT                = '::Float::NAN'.freeze

      ##
      # Attributes
      #
      attr_reader :field_options

      def initialize(field_descriptor, enclosing_msg_descriptor, indent_level)
        super(field_descriptor, indent_level)
        @enclosing_msg_descriptor = enclosing_msg_descriptor
      end

      def applicable_options
        # Note on the strange use of `#inspect`:
        #   :boom.inspect #=> ":boom"
        #   :".boom.foo".inspect #=> ":\".boom.foo\""
        # An alternative to `#inspect` would be always adding double quotes,
        # but the generatated code looks un-idiomatic:
        #   ":\"#{:boom}\"" #=> ":\"boom\"" <-- Note the unnecessary double quotes
        @applicable_options ||= field_options.map { |k, v| "#{k.inspect} => #{v}" }
      end

      def default_value
        @default_value ||= begin
                             if defaulted?
                               case descriptor.type.name
                               when :TYPE_ENUM
                                 enum_default_value
                               when :TYPE_STRING, :TYPE_BYTES
                                 string_default_value
                               when :TYPE_FLOAT, :TYPE_DOUBLE
                                 float_double_default_value
                               else
                                 verbatim_default_value
                               end
                             end
                           end
      end

      def defaulted?
        descriptor.respond_to_has_and_present?(:default_value)
      end

      def deprecated?
        descriptor.options.try(:deprecated?) { false }
      end

      def extension?
        descriptor.respond_to_has_and_present?(:extendee)
      end

      def compile
        run_once(:compile) do
          if map?
            field_definition = ["map #{map_key_type_name}", map_value_type_name, name, number, applicable_options]
          else
            field_definition = ["#{label} #{type_name}", name, number, applicable_options]
          end
          puts field_definition.flatten.compact.join(', ')
        end
      end

      def label
        @label ||= descriptor.label.name.to_s.downcase.sub(/label_/, '') # required, optional, repeated
      end

      def name
        @name ||= descriptor.name.to_sym.inspect
      end

      def number
        @number ||= descriptor.number
      end

      def field_options
        @field_options ||= begin
                             opts = {}
                             opts[:default] = default_value if defaulted?
                             opts[:packed] = 'true' if packed?
                             opts[:deprecated] = 'true' if deprecated?
                             opts[:extension] = 'true' if extension?
                             opts
                           end
      end

      def packed?
        descriptor.options.try(:packed?) { false }
      end

      # Determine the field type
      def type_name
        @type_name ||= determine_type_name(descriptor)
      end

      # If this field is a map field, this returns a message descriptor that
      # represents the entries in the map. Returns nil if this field is not
      # a map field.
      def map_entry
        @map_entry ||= determine_map_entry
      end

      def map?
        return not(map_entry.nil?)
      end

      def map_key_type_name
        e = map_entry
        return nil if e.nil?
        determine_type_name(e.field.find { |v| v.name == 'key' and v.number == 1 })
      end

      def map_value_type_name
        e = map_entry
        return nil if e.nil?
        determine_type_name(e.field.find { |v| v.name == 'value' and v.number == 2 })
      end

      private

      def enum_default_value
        "#{type_name}::#{verbatim_default_value}"
      end

      def float_double_default_value
        case verbatim_default_value
        when PROTO_INFINITY_DEFAULT then
          RUBY_INFINITY_DEFAULT
        when PROTO_NEGATIVE_INFINITY_DEFAULT then
          RUBY_NEGATIVE_INFINITY_DEFAULT
        when PROTO_NAN_DEFAULT then
          RUBY_NAN_DEFAULT
        else
          verbatim_default_value
        end
      end

      def string_default_value
        %("#{verbatim_default_value.gsub(/'/, '\\\\\'')}")
      end

      def verbatim_default_value
        descriptor.default_value
      end

      def determine_type_name(descriptor)
        case descriptor.type.name
        when :TYPE_MESSAGE, :TYPE_ENUM, :TYPE_GROUP then
          modulize(descriptor.type_name)
        else
          type_name = descriptor.type.name.to_s.downcase.sub(/type_/, '')
          ":#{type_name}"
        end
      end

      def determine_map_entry
        return nil unless descriptor.label.name == :LABEL_REPEATED and descriptor.type.name == :TYPE_MESSAGE
        # find nested message type
        name_parts = descriptor.type_name.split(".")
        return nil if name_parts.size < 2 or name_parts[-2] != @enclosing_msg_descriptor.name
        nested = @enclosing_msg_descriptor.nested_type.find { |e| e.name == name_parts[-1] }
        return nested if not(nested.nil?) and nested.options.try(:map_entry?) { false }
        return nil
      end

    end
  end
end
