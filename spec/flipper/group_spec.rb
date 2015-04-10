require 'helper'
require 'flipper/group'

describe Flipper::Group do
  subject do
    Flipper.register(:admins) { |actor| actor.admin? }
  end

  describe "#name" do
    it "returns name" do
      subject.name.should eq(:admins)
    end
  end

  describe "#match?" do
    let(:admin_actor) { double('Actor', :admin? => true) }
    let(:non_admin_actor) { double('Actor', :admin? => false) }

    it "returns true if block matches" do
      subject.match?(admin_actor).should eq(true)
    end

    it "returns false if block does not match" do
      subject.match?(non_admin_actor).should eq(false)
    end
  end
end
