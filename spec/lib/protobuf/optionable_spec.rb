require 'spec_helper'
require 'protobuf/optionable'

RSpec.describe 'Optionable' do
  describe '.{get,get!,set}_option' do
    before(:all) do
      OptionableGetOptionTest = ::Class.new(::Protobuf::Message) do
        set_option :deprecated, true
      end
    end

    it '.get_option retrieves the option as a symbol' do
      expect(OptionableGetOptionTest.get_option(:deprecated)).to be(true)
    end

    it '.get_option returns the default value for unset options' do
      expect(OptionableGetOptionTest.get_option(:message_set_wire_format)).to be(false)
    end

    it '.get_option retrieves the option as a string' do
      expect(OptionableGetOptionTest.get_option('deprecated')).to be(true)
    end

    it '.get_option errors if the option does not exist' do
      expect { OptionableGetOptionTest.get_option(:baz) }.to raise_error(ArgumentError)
    end

    it '.get_option! retrieves explicitly an set option' do
      expect(OptionableGetOptionTest.get_option!(:deprecated)).to be(true)
    end

    it '.get_option! returns nil for unset options' do
      expect(OptionableGetOptionTest.get_option!(:message_set_wire_format)).to be(nil)
    end

    it '.get_option! errors if the option does not exist' do
      expect { OptionableGetOptionTest.get_option(:baz) }.to raise_error(ArgumentError)
    end

    it '#get_option retrieves the option as a symbol' do
      expect(OptionableGetOptionTest.new.get_option(:deprecated)).to be(true)
    end

    it '#get_option returns the default value for unset options' do
      expect(OptionableGetOptionTest.new.get_option(:message_set_wire_format)).to be(false)
    end

    it '#get_option retrieves the option as a string' do
      expect(OptionableGetOptionTest.new.get_option('deprecated')).to be(true)
    end

    it '#get_option errors if the option does not exist' do
      expect { OptionableGetOptionTest.new.get_option(:baz) }.to raise_error(ArgumentError)
    end

    it '#get_option! retrieves explicitly an set option' do
      expect(OptionableGetOptionTest.new.get_option!(:deprecated)).to be(true)
    end

    it '#get_option! returns nil for unset options' do
      expect(OptionableGetOptionTest.new.get_option!(:message_set_wire_format)).to be(nil)
    end

    it '#get_option! errors if the option does not exist' do
      expect { OptionableGetOptionTest.new.get_option(:baz) }.to raise_error(ArgumentError)
    end
  end

  describe '.inject' do
    let(:klass) { Class.new }

    it 'adds klass.{set,get}_option' do
      expect { klass.get_option(:deprecated) }.to raise_error(NoMethodError)
      expect { klass.set_option(:deprecated, true) }.to raise_error(NoMethodError)
      ::Protobuf::Optionable.inject(klass) { ::Google::Protobuf::MessageOptions }
      expect(klass.get_option(:deprecated)).to eq(false)
      klass.set_option(:deprecated, true)
      expect(klass.get_option(:deprecated)).to eq(true)
    end

    it 'adds klass#get_option' do
      expect { klass.new.get_option(:deprecated) }.to raise_error(NoMethodError)
      ::Protobuf::Optionable.inject(klass) { ::Google::Protobuf::MessageOptions }
      expect(klass.new.get_option(:deprecated)).to eq(false)
    end

    it 'adds klass.optionable_descriptor_class' do
      expect { klass.optionable_descriptor_class }.to raise_error(NoMethodError)
      ::Protobuf::Optionable.inject(klass) { ::Google::Protobuf::MessageOptions }
      expect(klass.optionable_descriptor_class).to eq(::Google::Protobuf::MessageOptions)
    end

    context 'extend_class = false' do
      let(:object) { klass.new }
      it 'adds object.{get,set}_option' do
        expect { object.get_option(:deprecated) }.to raise_error(NoMethodError)
        expect { object.set_option(:deprecated, true) }.to raise_error(NoMethodError)
        ::Protobuf::Optionable.inject(klass, false) { ::Google::Protobuf::MessageOptions }
        expect(object.get_option(:deprecated)).to eq(false)
        object.set_option(:deprecated, true)
        expect(object.get_option(:deprecated)).to eq(true)
      end

      it 'creates an instance method optionable_descriptor_class' do
        expect { object.optionable_descriptor_class }.to raise_error(NoMethodError)
        ::Protobuf::Optionable.inject(klass, false) { ::Google::Protobuf::MessageOptions }
        expect(object.optionable_descriptor_class).to eq(::Google::Protobuf::MessageOptions)
      end
    end
  end
end
