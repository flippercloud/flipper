require 'helper'
require 'flipper/ui/util'

describe Flipper::UI::Util do
  describe "#blank?" do
    context "with a string" do
      it "returns true if blank" do
        described_class.blank?(nil).should be(true)
        described_class.blank?('').should be(true)
        described_class.blank?('   ').should be(true)
      end

      it "returns false if not blank" do
        described_class.blank?('nope').should be(false)
      end
    end
  end
end
