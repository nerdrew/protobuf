module Protobuf
  module Optionable
    module ClassMethods
      def get_option(name)
        name = name.to_s
        option = optionable_descriptor_class.get_field(name, true)
        raise ArgumentError, "invalid option=#{name}" unless option
        if @_optionable_options.try(:key?, name)
          value = @_optionable_options[name]
        else
          value = option.default_value
        end
        if option.type_class < ::Protobuf::Message
          option.type_class.new(value)
        else
          value
        end
      end

      def get_option!(name)
        get_option(name) if @_optionable_options.try(:key?, name.to_s)
      end

      def set_option(name, value = true)
        @_optionable_options ||= {}
        @_optionable_options[name.to_s] = value
      end
    end

    def get_option(name)
      self.class.get_option(name)
    end

    def get_option!(name)
      self.class.get_option!(name)
    end

    def self.inject(base_class, extend_class = true, &block)
      unless block_given?
        raise ArgumentError, 'missing option class block (e.g: ::Google::Protobuf::MessageOptions)'
      end
      if extend_class
        base_class.extend(ClassMethods)
        base_class.include(self)
        base_class.define_singleton_method(:optionable_descriptor_class, block)
      else
        base_class.include(ClassMethods)
        base_class.module_eval { define_method(:optionable_descriptor_class, block) }
      end
    end
  end
end
