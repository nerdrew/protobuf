require 'spec_helper'
require 'protobuf/optionable'

RSpec.describe 'Optionable' do
  describe '.{get,set}_option' do
    before(:all) do
      OptionableGetOptionTest = ::Class.new(::Protobuf::Message) do
        set_option :deprecated, true
      end
    end

    it 'retrieves the option for the given name, if any' do
      expect(OptionableGetOptionTest.get_option(:deprecated)).to be(true)
      expect(OptionableGetOptionTest.get_option("deprecated")).to be(true)
      expect { OptionableGetOptionTest.get_option(:baz) }.to raise_error(ArgumentError)
    end

    it 'retrieves the option in the context of an instance' do
      expect(OptionableGetOptionTest.new.get_option(:deprecated)).to be(true)
      expect(OptionableGetOptionTest.new.get_option("deprecated")).to be(true)
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
