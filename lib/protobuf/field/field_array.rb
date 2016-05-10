module Protobuf
  module Field
    class FieldArray < Array

      ##
      # Attributes
      #

      attr_reader :field

      ##
      # Constructor
      #

      def initialize(field)
        @field = field
      end

      ##
      # Public Instance Methods
      #

      def []=(nth, val)
        if nth < 0 || nth > size
          fail IndexError, "Index #{nth} is outside valid range 0...#{size}"
        end
        super(nth, normalize(val))
      end

      def <<(val)
        super(normalize(val))
      end

      alias_method :push, :<<

      def unshift(val)
        super(normalize(val))
      end

      def replace(val)
        raise_type_error(val) unless val.is_a?(Array)
        super(val.map { |v| normalize(v) })
      end

      def map!(&block)
        if block_given?
          new_ary = map(&block)
          replace(new_ary)
        else
          super()
        end
      end

      def fill(*args, &block)
        new_ary = Array.new(self).fill(*args, &block)
        replace(new_ary)
      end

      def concat(other)
        ary = FieldArray.new(field)
        ary.replace(other)
        super(ary)
      end

      def insert(index, *objs)
        ary = FieldArray.new(field)
        ary.replace(objs)
        super(index, *ary)
      end

      # Return a hash-representation of the given values for this field type.
      # The value in this case would be an array.
      def to_hash_value
        map do |value|
          value.respond_to?(:to_hash_value) ? value.to_hash_value : value
        end
      end

      def to_s
        "[#{field.name}]"
      end

      private

      ##
      # Private Instance Methods
      #

      def normalize(value)
        if value.nil?
          raise_type_error(value)
        end
        value = value.to_proto if value.respond_to?(:to_proto)
        fail TypeError, "Unacceptable value #{value} for field #{field.name} of type #{field.type_class}" unless field.acceptable?(value)

        if field.is_a?(::Protobuf::Field::EnumField)
          fetch_enum(field.type_class, value)
        elsif field.is_a?(::Protobuf::Field::MessageField) && value.is_a?(field.type_class)
          value
        elsif field.is_a?(::Protobuf::Field::MessageField) && value.respond_to?(:to_hash)
          field.type_class.new(value.to_hash)
        else
          value
        end
      end

      def fetch_enum(type, val)
        en = type.fetch(val)
        raise_type_error(val) if en.nil?
        en
      end

      def raise_type_error(val)
        fail TypeError, <<-TYPE_ERROR
          Expected repeated value of type '#{field.type_class}'
          Got '#{val.class}' for repeated protobuf field #{field.name}
        TYPE_ERROR
      end

    end
  end
end
