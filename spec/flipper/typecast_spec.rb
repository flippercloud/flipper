require 'flipper/typecast'

RSpec.describe Flipper::Typecast do
  {
    nil => false,
    '' => false,
    0 => false,
    1 => true,
    '0' => false,
    '1' => true,
    true => true,
    false => false,
    'true' => true,
    'false' => false,
  }.each do |value, expected|
    context "#to_boolean for #{value.inspect}" do
      it "returns #{expected}" do
        expect(described_class.to_boolean(value)).to be(expected)
      end
    end
  end

  {
    nil => 0,
    '' => 0,
    0 => 0,
    1 => 1,
    '1' => 1,
    '99' => 99,
  }.each do |value, expected|
    context "#to_integer for #{value.inspect}" do
      it "returns #{expected}" do
        expect(described_class.to_integer(value)).to be(expected)
      end
    end
  end

  {
    nil => 0.0,
    '' => 0.0,
    0 => 0.0,
    1 => 1.0,
    1.1 => 1.1,
    '0.01' => 0.01,
    '1' => 1.0,
    '99' => 99.0,
  }.each do |value, expected|
    context "#to_float for #{value.inspect}" do
      it "returns #{expected}" do
        expect(described_class.to_float(value)).to be(expected)
      end
    end
  end

  {
    nil => 0,
    '' => 0,
    0 => 0,
    0.0 => 0.0,
    1 => 1,
    1.1 => 1.1,
    '0.01' => 0.01,
    '1' => 1,
    '1.1' => 1.1,
    '99' => 99,
    '99.9' => 99.9,
  }.each do |value, expected|
    context "#to_number for #{value.inspect}" do
      it "returns #{expected}" do
        expect(described_class.to_number(value)).to be(expected)
      end
    end
  end

  {
    nil => Set.new,
    '' => Set.new,
    Set.new([1, 2]) => Set.new([1, 2]),
    [1, 2] => Set.new([1, 2]),
  }.each do |value, expected|
    context "#to_set for #{value.inspect}" do
      it "returns #{expected}" do
        expect(described_class.to_set(value)).to eq(expected)
      end
    end
  end

  it 'raises argument error for integer value that cannot be converted to an integer' do
    expect do
      described_class.to_integer(['asdf'])
    end.to raise_error(ArgumentError, %(["asdf"] cannot be converted to an integer))
  end

  it 'raises argument error for float value that cannot be converted to an float' do
    expect do
      described_class.to_float(['asdf'])
    end.to raise_error(ArgumentError, %(["asdf"] cannot be converted to a float))
  end

  it 'raises argument error for bad integer percentage' do
    expect do
      described_class.to_number(['asdf'])
    end.to raise_error(ArgumentError, %(["asdf"] cannot be converted to a number))
  end

  it 'raises argument error for bad float percentage' do
    expect do
      described_class.to_number(['asdf.0'])
    end.to raise_error(ArgumentError, %(["asdf.0"] cannot be converted to a number))
  end

  it 'raises argument error for set value that cannot be converted to a set' do
    expect do
      described_class.to_set('asdf')
    end.to raise_error(ArgumentError, %("asdf" cannot be converted to a set))
  end

  describe "#features_hash" do
    it "returns new hash" do
      hash = {
        "search" => {
          boolean: nil,
        }
      }
      result = described_class.features_hash(hash)
      expect(result).not_to be(hash)
      expect(result["search"]).not_to be(hash["search"])
    end

    it "converts does not convert expressions" do
      hash = {
        "search" => {
          boolean: nil,
          expression: {"Equal"=>[{"Property"=>["plan"]}, "basic"]},
          groups: ['a', 'b'],
          actors: ['User;1'],
          percentage_of_actors: nil,
          percentage_of_time: nil,
        },
      }
      result = described_class.features_hash(hash)
      expect(result).to eq({
        "search" => {
          boolean: nil,
          expression: {"Equal"=>[{"Property"=>["plan"]}, "basic"]},
          groups: Set['a', 'b'],
          actors: Set['User;1'],
          percentage_of_actors: nil,
          percentage_of_time: nil,
        },
      })
    end

    it "converts gate value arrays to sets" do
      hash = {
        "search" => {
          boolean: nil,
          groups: ['a', 'b'],
          actors: ['User;1'],
          percentage_of_actors: nil,
          percentage_of_time: nil,
        },
      }
      result = described_class.features_hash(hash)
      expect(result).to eq({
        "search" => {
          boolean: nil,
          groups: Set['a', 'b'],
          actors: Set['User;1'],
          percentage_of_actors: nil,
          percentage_of_time: nil,
        },
      })
    end

    it "converts gate value boolean and integers to strings" do
      hash = {
        "search" => {
          boolean: true,
          groups: Set.new,
          actors: Set.new,
          percentage_of_actors: 10,
          percentage_of_time: 15,
        },
      }
      result = described_class.features_hash(hash)
      expect(result).to eq({
        "search" => {
          boolean: "true",
          groups: Set.new,
          actors: Set.new,
          percentage_of_actors: "10",
          percentage_of_time: "15",
        },
      })
    end

    it "converts string gate keys to symbols" do
      hash = {
        "search" => {
          "boolean" => nil,
          "groups" => Set.new,
          "actors" => Set.new,
          "percentage_of_actors" => nil,
          "percentage_of_time" => nil,
        },
      }
      result = described_class.features_hash(hash)
      expect(result).to eq({
        "search" => {
          boolean: nil,
          groups: Set.new,
          actors: Set.new,
          percentage_of_actors: nil,
          percentage_of_time: nil,
        },
      })
    end
  end


  describe "to_feature_name" do
    it "keeps accented and non-latin characters" do
      expect(described_class.to_feature_name("caf\u00E9")).to eq("caf\u00E9")
      expect(described_class.to_feature_name("\u65B0\u6A5F\u80FD")).to eq("\u65B0\u6A5F\u80FD")
    end

    it "removes invisible format and control characters" do
      expect(described_class.to_feature_name("f\u200Bea\u2060ture")).to eq("feature")
      expect(described_class.to_feature_name("\uFEFFfeat\u00ADure")).to eq("feature")
      expect(described_class.to_feature_name("feat\u0000ure")).to eq("feature")
    end

    it "trims unicode whitespace" do
      expect(described_class.to_feature_name("\u00A0feature\u3000")).to eq("feature")
      expect(described_class.to_feature_name("  feature  ")).to eq("feature")
    end

    it "removes invalid utf-8 bytes" do
      expect(described_class.to_feature_name("feature\xFF".dup.force_encoding(Encoding::UTF_8))).to eq("feature")
    end

    it "returns empty string for nil" do
      expect(described_class.to_feature_name(nil)).to eq("")
    end
  end

  it "converts to and from json" do
    source = {"foo" => "bar"}
    output = described_class.to_json(source)
    expect(described_class.from_json(output)).to eq(source)
  end

  it "converts to and from gzip" do
    source = "foo bar"
    output = described_class.to_gzip(source)
    expect(described_class.from_gzip(output)).to eq(source)
  end
end
