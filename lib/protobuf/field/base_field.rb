require 'protobuf/message'
require 'active_support/core_ext/hash/slice'
require 'protobuf/field/field_array'
require 'protobuf/field/field_hash'
require 'protobuf/logging'
require 'protobuf/wire_type'

module Protobuf
  module Field
    class BaseField
      include ::Protobuf::Logging
      ::Protobuf::Optionable.inject(self, false) { ::Google::Protobuf::FieldOptions }

      ##
      # Constants
      #

      PACKED_TYPES = [
        ::Protobuf::WireType::VARINT,
        ::Protobuf::WireType::FIXED32,
        ::Protobuf::WireType::FIXED64,
      ].freeze

      ##
      # Attributes
      #
      attr_reader :message_class, :name, :fully_qualified_name, :options, :rule, :tag, :type_class

      ##
      # Class Methods
      #

      def self.default
        nil
      end

      ##
      # Constructor
      #

      def initialize(message_class, rule, type_class, fully_qualified_name, tag, simple_name, options)
        @message_class = message_class
        @name = simple_name || fully_qualified_name
        @fully_qualified_name = fully_qualified_name
        @rule          = rule
        @tag           = tag
        @type_class    = type_class
        @options = options.slice(:ctype, :packed, :deprecated, :lazy, :jstype, :weak, :uninterpreted_option, :default, :extension)
        options.each do |option_name, value|
          set_option(option_name, value)
        end

        validate_packed_field if packed?
        define_accessor(simple_name, fully_qualified_name) if simple_name
        tag_encoded
      end

      ##
      # Public Instance Methods
      #

      def acceptable?(_value)
        true
      end

      def coerce!(value)
        value
      end

      def decode(_bytes)
        fail NotImplementedError, "#{self.class.name}##{__method__}"
      end

      def default
        options[:default]
      end

      def default_value
        @default_value ||= if optional? || required?
                             typed_default_value
                           elsif map?
                             ::Protobuf::Field::FieldHash.new(self).freeze
                           elsif repeated?
                             ::Protobuf::Field::FieldArray.new(self).freeze
                           else
                             fail "Unknown field label -- something went very wrong"
                           end
      end

      def deprecated?
        options.key?(:deprecated)
      end

      def encode(_value)
        fail NotImplementedError, "#{self.class.name}##{__method__}"
      end

      def extension?
        options.key?(:extension)
      end

      def enum?
        false
      end

      def message?
        false
      end

      def map?
        repeated_message? and type_class.get_option(:map_entry)
      end

      def optional?
        rule == :optional
      end

      def packed?
        repeated? && options.key?(:packed)
      end

      def repeated?
        rule == :repeated
      end

      def repeated_message?
        repeated? && message?
      end

      def required?
        rule == :required
      end

      # FIXME: need to cleanup (rename) this warthog of a method.
      def set(message_instance, bytes)
        return message_instance[name] = decode(bytes) unless repeated?

        if map?
          hash = message_instance[name]
          entry = decode(bytes)
          # decoded value could be nil for an
          # enum value that is not recognized
          hash[entry.key] = entry.value if not(entry.value.nil?)
          return
        end

        return message_instance[name] << decode(bytes) unless packed?

        array = message_instance[name]
        stream = StringIO.new(bytes)

        if wire_type == ::Protobuf::WireType::VARINT
          array << Varint.decode(stream) until stream.eof?
        elsif wire_type == ::Protobuf::WireType::FIXED64
          array << stream.read(8) until stream.eof?
        elsif wire_type == ::Protobuf::WireType::FIXED32
          array << stream.read(4) until stream.eof?
        end
      end

      def tag_encoded
        @tag_encoded ||= begin
                           case
                           when repeated? && packed?
                             ::Protobuf::Field::VarintField.encode((tag << 3) | ::Protobuf::WireType::LENGTH_DELIMITED)
                           else
                             ::Protobuf::Field::VarintField.encode((tag << 3) | wire_type)
                           end
                         end
      end

      # FIXME: add packed, deprecated, extension options to to_s output
      def to_s
        "#{rule} #{type_class} #{name} = #{tag} #{default ? "[default=#{default.inspect}]" : ''}"
      end

      ::Protobuf.deprecator.define_deprecated_methods(self, :type => :type_class)

      def wire_type
        ::Protobuf::WireType::VARINT
      end

      def fully_qualified_name_only!
        @name = @fully_qualified_name
      end

      private

      ##
      # Private Instance Methods
      #

      def define_accessor(simple_field_name, fully_qualified_field_name)
        message_class.class_eval do
          define_method("#{simple_field_name}!") do
            @values[fully_qualified_field_name] if field?(fully_qualified_field_name)
          end
        end

        message_class.class_eval do
          define_method(simple_field_name) { self[fully_qualified_field_name] }
          define_method("#{simple_field_name}=") { |v| self[fully_qualified_field_name] = v }
        end

        return unless deprecated?

        ::Protobuf.field_deprecator.deprecate_method(message_class, simple_field_name)
        ::Protobuf.field_deprecator.deprecate_method(message_class, "#{simple_field_name}!")
        ::Protobuf.field_deprecator.deprecate_method(message_class, "#{simple_field_name}=")
      end

      def typed_default_value
        if default.nil?
          self.class.default
        else
          default
        end
      end

      def validate_packed_field
        if packed? && ! ::Protobuf::Field::BaseField::PACKED_TYPES.include?(wire_type)
          fail "Can't use packed encoding for '#{type_class}' type"
        end
      end
    end
  end
end
