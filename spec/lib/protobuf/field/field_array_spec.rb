require 'spec_helper'

RSpec.describe Protobuf::Field::FieldArray do

  let(:basic_message) do
    Class.new(::Protobuf::Message) do
      optional :string, :field, 1
    end
  end

  let(:more_complex_message) do
    Class.new(BasicMessage) do
    end
  end

  let(:some_enum) do
    Class.new(::Protobuf::Enum) do
      define :FOO, 1
      define :BAR, 2
      define :BAZ, 3
    end
  end

  let(:repeat_message) do
    Class.new(::Protobuf::Message) do
      optional :string, :some_string, 1
      repeated :string, :multiple_strings, 2
      repeated BasicMessage, :multiple_basic_msgs, 3
      repeated SomeEnum, :multiple_enums, 4
    end
  end

  before do
    stub_const('BasicMessage', basic_message)
    stub_const('MoreComplexMessage', more_complex_message)
    stub_const('SomeEnum', some_enum)
    stub_const('SomeRepeatMessage', repeat_message)
  end

  let(:instance) { SomeRepeatMessage.new }

  %w(<< push).each do |method|
    describe "\##{method}" do
      context 'when applied to a string field array' do
        it 'adds a string' do
          expect(instance.multiple_strings).to be_empty
          instance.multiple_strings.send(method, 'string 1')
          expect(instance.multiple_strings).to eq(['string 1'])
          instance.multiple_strings.send(method, 'string 2')
          expect(instance.multiple_strings).to eq(['string 1', 'string 2'])
        end

        it 'fails if not adding a string' do
          expect { instance.multiple_strings.send(method, 100.0) }.to raise_error(TypeError)
          expect { instance.multiple_strings.send(method, nil) }.to raise_error(TypeError)
        end
      end

      context 'when applied to a MessageField field array' do
        it 'adds a MessageField object' do
          expect(instance.multiple_basic_msgs).to be_empty
          basic_msg1 = BasicMessage.new
          instance.multiple_basic_msgs.send(method, basic_msg1)
          expect(instance.multiple_basic_msgs).to eq([basic_msg1])
          basic_msg2 = BasicMessage.new
          instance.multiple_basic_msgs.send(method, basic_msg2)
          expect(instance.multiple_basic_msgs).to eq([basic_msg1, basic_msg2])
        end

        it 'fails if not adding a MessageField' do
          expect { instance.multiple_basic_msgs.send(method, 100.0) }.to raise_error(TypeError)
          expect { instance.multiple_basic_msgs.send(method, nil) }.to raise_error(TypeError)
        end

        it 'adds a Hash from a MessageField object' do
          expect(instance.multiple_basic_msgs).to be_empty
          basic_msg1 = BasicMessage.new
          basic_msg1.field = 'my value'
          instance.multiple_basic_msgs.send(method, basic_msg1.to_hash)
          expect(instance.multiple_basic_msgs).to eq([basic_msg1])
        end

        it 'does not downcast a MessageField' do
          expect(instance.multiple_basic_msgs).to be_empty
          basic_msg1 = MoreComplexMessage.new
          instance.multiple_basic_msgs.send(method, basic_msg1)
          expect(instance.multiple_basic_msgs).to eq([basic_msg1])
          expect(instance.multiple_basic_msgs.first).to be_a(MoreComplexMessage)
        end
      end

      context 'when applied to an EnumField field array' do
        it 'adds an EnumField object' do
          expect(instance.multiple_enums).to be_empty
          instance.multiple_enums.send(method, SomeEnum::FOO)
          expect(instance.multiple_enums).to eq([SomeEnum::FOO])
          instance.multiple_enums.send(method, SomeEnum::BAR)
          expect(instance.multiple_enums).to eq([SomeEnum::FOO, SomeEnum::BAR])
        end

        it 'fails if not adding an EnumField' do
          expect { instance.multiple_basic_msgs.send(method, 100.0) }.to raise_error(TypeError)
          expect { instance.multiple_basic_msgs.send(method, nil) }.to raise_error(TypeError)
        end
      end      
    end
  end

  describe "#[]=" do
    it 'adds values, coercing when needed' do
      instance.multiple_strings << "foo" << "bar"
      instance.multiple_strings[0] = "string"
      expect(instance.multiple_strings).to eq(["string", "bar"])

      instance.multiple_enums[0] = 1
      expect(instance.multiple_enums).to eq([SomeEnum::FOO])

      instance.multiple_basic_msgs[0] = { :field => "string" }
      expect(instance.multiple_basic_msgs).to eq([BasicMessage.new({ :field => "string" })])
    end

    it 'rejects values of incorrect type' do
      expect { instance.multiple_strings[0] = 1 }.to raise_error(TypeError)
      expect { instance.multiple_enums[0] = -99 }.to raise_error(TypeError)
      expect { instance.multiple_basic_msgs[0] = nil }.to raise_error(TypeError)
    end

    it 'allows appending' do
      instance.multiple_strings[0] = 'abc'
      instance.multiple_strings[1] = 'def'
      instance.multiple_strings[2] = 'ghi'
      instance.multiple_strings[3] = 'jkl'
      expect(instance.multiple_strings).to eq(["abc", "def", "ghi", "jkl"])
    end

    it 'disallows random access insertions' do
      expect { instance.multiple_strings[5] = 'abc' }.to raise_error(IndexError)
    end
  end

  describe "#map!" do
    it 'succeeds when function result is correct type' do
      instance.multiple_strings << 'abc'
      instance.multiple_strings.map! { |i| i + i }
      expect(instance.multiple_strings).to eq(["abcabc"])

      instance.multiple_basic_msgs << { :field => 'foobar' }
      instance.multiple_basic_msgs.map! { |i| { :field => 'baz' } }
      expect(instance.multiple_basic_msgs).to eq([BasicMessage.new({ :field => 'baz' })])
    end

    it 'fails if function result is wrong type' do
      instance.multiple_strings << 'abc'
      expect { instance.multiple_strings.map! { |i| BasicMessage.new } }.to raise_error(TypeError)
      expect { instance.multiple_strings.map! { |i| i.size } }.to raise_error(TypeError)
    end
  end

  describe "#fill" do
    it 'succeeds when function result is correct type' do
      instance.multiple_strings << 'abc' << 'def'
      instance.multiple_strings.fill('xyz')
      expect(instance.multiple_strings).to eq(["xyz", "xyz"])
      instance.multiple_strings.fill('abc', 0..0)
      expect(instance.multiple_strings).to eq(["abc", "xyz"])
      instance.multiple_strings.fill('foo', 1, 2)
      expect(instance.multiple_strings).to eq(["abc", "foo", "foo"])
      instance.multiple_strings.fill { |i| 'foo' + i.to_s }
      expect(instance.multiple_strings).to eq(["foo0", "foo1", "foo2"])
      instance.multiple_strings.fill(2) { |i| 'bar' }
      expect(instance.multiple_strings).to eq(["foo0", "foo1", "bar"])
      instance.multiple_strings.fill(0..1) { |i| 'baz' }
      expect(instance.multiple_strings).to eq(["baz", "baz", "bar"])
    end

    it 'fails if function result is wrong type' do
      instance.multiple_strings << 'abc' << 'def'
      expect { instance.multiple_strings.fill(1) }.to raise_error(TypeError)
      expect { instance.multiple_strings.fill(BasicMessage.new, 0..1) }.to raise_error(TypeError)
      expect { instance.multiple_strings.fill { |i| i + 1 } }.to raise_error(TypeError)
      expect { instance.multiple_strings.fill(1, 1) { |i| BasicMessage.new} }.to raise_error(TypeError)
    end
  end

  describe "#concat" do
    it 'succeeds when function result is correct type' do
      instance.multiple_strings << 'abc' << 'def'
      instance.multiple_strings.concat(["foo", "bar"])
      expect(instance.multiple_strings).to eq(["abc", "def", "foo", "bar"])

      instance.multiple_enums << SomeEnum::FOO
      instance.multiple_enums.concat([SomeEnum::BAZ, SomeEnum::BAR])
      expect(instance.multiple_enums).to eq([SomeEnum::FOO, SomeEnum::BAZ, SomeEnum::BAR])
    end

    it 'fails if function result is wrong type' do
      instance.multiple_strings << 'abc' << 'def'
      expect { instance.multiple_strings.concat([1, 2, 3]) }.to raise_error(TypeError)
      expect { instance.multiple_strings.concat([BasicMessage.new]) }.to raise_error(TypeError)
    end
  end

  describe "#insert" do
    it 'succeeds when function result is correct type' do
      instance.multiple_strings << 'abc' << 'def'
      instance.multiple_strings.insert(1, 'foo', 'bar')
      expect(instance.multiple_strings).to eq(["abc", "foo", "bar", "def"])
      instance.multiple_strings.insert(-1, 'baz')
      expect(instance.multiple_strings).to eq(["abc", "foo", "bar", "def", "baz"])
      instance.multiple_strings.insert(0, 'xyz')
      expect(instance.multiple_strings).to eq(["xyz", "abc", "foo", "bar", "def", "baz"])
    end

    it 'fails if function result is wrong type' do
      instance.multiple_strings << 'abc' << 'def'
      expect { instance.multiple_strings.insert(0, 1, 2) }.to raise_error(TypeError)
      expect { instance.multiple_strings.insert(-1, BasicMessage.new, 0..1) }.to raise_error(TypeError)
    end
  end
end
