require 'spec_helper'

RSpec.describe Protobuf::Field::FieldHash do

  class FieldHashBasicMessage < ::Protobuf::Message
    optional :string, :field, 1
  end

  class FieldHashMoreComplexMessage < FieldHashBasicMessage
  end

  class SomeMapMessage < ::Protobuf::Message
    optional :string, :some_string, 1
    map :int32, :string, :map_int32_to_string, 2
    map :string, FieldHashBasicMessage, :map_string_to_msg, 3
  end

  let(:instance) { SomeMapMessage.new }

  %w([]= store).each do |method|
    describe "\##{method}" do
      context 'when applied to an int32->string field hash' do
        it 'adds an int -> string entry' do
          expect(instance.map_int32_to_string).to be_empty
          instance.map_int32_to_string.send(method, 1, 'string 1')
          expect(instance.map_int32_to_string).to eq({ 1 => 'string 1' })
          instance.map_int32_to_string.send(method, 2, 'string 2')
          expect(instance.map_int32_to_string).to eq({ 1 => 'string 1', 2 => 'string 2' })
        end

        it 'fails if not adding an int -> string' do
          expect { instance.map_int32_to_string.send(method, 'foo', 100.0) }.to raise_error(TypeError)
          expect { instance.map_int32_to_string.send(method, FieldHashBasicMessage.new, 100.0) }.to raise_error(TypeError)
        end
      end

      context 'when applied to a string->MessageField field hash' do
        it 'adds a string -> MessageField entry' do
          expect(instance.map_string_to_msg).to be_empty
          basic_msg1 = FieldHashBasicMessage.new
          instance.map_string_to_msg.send(method, 'msg1', basic_msg1)
          expect(instance.map_string_to_msg).to eq({ 'msg1' => basic_msg1 })
          basic_msg2 = FieldHashBasicMessage.new
          instance.map_string_to_msg.send(method, 'msg2', basic_msg2)
          expect(instance.map_string_to_msg).to eq({ 'msg1' => basic_msg1, 'msg2' => basic_msg2 })
        end

        it 'adds a Hash from a MessageField object' do
          expect(instance.map_string_to_msg).to be_empty
          basic_msg1 = FieldHashBasicMessage.new
          basic_msg1.field = 'my value'
          instance.map_string_to_msg.send(method, 'foo', basic_msg1.to_hash)
          expect(instance.map_string_to_msg).to eq({ 'foo' => basic_msg1 })
        end

        it 'does not downcast a MessageField' do
          expect(instance.map_string_to_msg).to be_empty
          basic_msg1 = FieldHashMoreComplexMessage.new
          instance.map_string_to_msg.send(method, 'foo', basic_msg1)
          expect(instance.map_string_to_msg).to eq({ 'foo' => basic_msg1 })
          expect(instance.map_string_to_msg['foo']).to be_a(FieldHashMoreComplexMessage)
        end
      end
    end
  end
end
