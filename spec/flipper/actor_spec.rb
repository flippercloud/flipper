require 'helper'

RSpec.describe Flipper::Actor do
  it 'initializes with and knows flipper_id' do
    actor = described_class.new("User;235")
    expect(actor.flipper_id).to eq("User;235")
  end

  describe '#eql?' do
    it 'returns true if same class and flipper_id' do
      actor1 = described_class.new("User;235")
      actor2 = described_class.new("User;235")
      expect(actor1.eql?(actor2)).to be(true)
    end

    it 'returns false if same class but different flipper_id' do
      actor1 = described_class.new("User;235")
      actor2 = described_class.new("User;1")
      expect(actor1.eql?(actor2)).to be(false)
    end

    it 'returns false for different class' do
      actor1 = described_class.new("User;235")
      actor2 = Struct.new(:flipper_id).new("User;235")
      expect(actor1.eql?(actor2)).to be(false)
    end
  end

  describe '#==' do
    it 'returns true if same class and flipper_id' do
      actor1 = described_class.new("User;235")
      actor2 = described_class.new("User;235")
      expect(actor1.==(actor2)).to be(true)
    end

    it 'returns false if same class but different flipper_id' do
      actor1 = described_class.new("User;235")
      actor2 = described_class.new("User;1")
      expect(actor1.==(actor2)).to be(false)
    end

    it 'returns false for different class' do
      actor1 = described_class.new("User;235")
      actor2 = Struct.new(:flipper_id).new("User;235")
      expect(actor1.==(actor2)).to be(false)
    end
  end
end
