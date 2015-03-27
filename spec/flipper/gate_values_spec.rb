require 'helper'
require 'flipper/gate_values'

describe Flipper::GateValues do
  {
    nil => false,
    "" => false,
    0 => false,
    1 => true,
    "0" => false,
    "1" => true,
    true => true,
    false => false,
    "true" => true,
    "false" => false,
  }.each do |value, expected|
    context "with #{value.inspect} boolean" do
      it "returns #{expected}" do
        described_class.new(boolean: value).boolean.should be(expected)
      end
    end
  end
end
