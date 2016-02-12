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
      expect { OptionableGetOptionTest.get_option(:baz) }.to raise_error(ArgumentError)
    end

    it 'retrieves the option in the context of an instance' do
      expect(OptionableGetOptionTest.new.get_option(:deprecated)).to be(true)
      expect { OptionableGetOptionTest.new.get_option(:baz) }.to raise_error(ArgumentError)
    end
  end
end
