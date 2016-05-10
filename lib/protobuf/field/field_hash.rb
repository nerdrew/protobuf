module Protobuf
  module Field
    class FieldHash < Hash

      ##
      # Attributes
      #

      attr_reader :field, :key_field, :value_field

      ##
      # Constructor
      #

      def initialize(field)
        @field = field
        @key_field = field.type_class.get_field(:key)
        @value_field = field.type_class.get_field(:value)
      end

      ##
      # Public Instance Methods
      #

      def []=(key, val)
        super(normalize_key(key), normalize_val(val))
      end

      alias_method :store, :[]=

      def replace(val)
        raise_type_error(val) unless val.is_a?(Hash)
        clear
        update(val)
      end

      def merge!(other)
        raise_type_error(other) unless other.is_a?(Hash)
        # keys and values will be normalized by []= above
        other.each { |k, v| self[k] = v }
      end

      alias_method :update, :merge!

      # Return a hash-representation of the given values for this field type.
      # The value in this case would be the hash itself.
      def to_hash_value
        self
      end

      def to_s
        "{#{field.name}}"
      end

      private

      ##
      # Private Instance Methods
      #

      def normalize_key(key)
        normalize(:key, key, key_field)
      end

      def normalize_val(value)
        normalize(:value, value, value_field)
      end

      def normalize(what, value, normalize_field)
        if value.nil?
          raise_type_error(value)
        end
        value = value.to_proto if value.respond_to?(:to_proto)
        fail TypeError, "Unacceptable #{what} #{value} for field #{field.name} of type #{normalize_field.type_class}" unless normalize_field.acceptable?(value)

        if normalize_field.is_a?(::Protobuf::Field::EnumField)
          fetch_enum(normalize_field.type_class, value)
        elsif normalize_field.is_a?(::Protobuf::Field::MessageField) && value.is_a?(normalize_field.type_class)
          value
        elsif normalize_field.is_a?(::Protobuf::Field::MessageField) && value.respond_to?(:to_hash)
          normalize_field.type_class.new(value.to_hash)
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
          Expected map value of type '#{key_field.type_class} -> #{value_field.type_class}'
          Got '#{val.class}' for map protobuf field #{field.name}
        TYPE_ERROR
      end

    end
  end
end
