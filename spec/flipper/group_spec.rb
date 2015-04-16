require 'helper'
require 'flipper/group'

describe Flipper::Group do
  subject do
    Flipper.register(:admins) { |actor| actor.admin? }
  end

  it "does not allow names containing \\x1E" do
    expect {
      Flipper.register("foo\x1Ebar") { }
    }.to raise_error(ArgumentError)
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

  describe "with block parameter" do
    subject do
      Flipper.register(:team) { |actor, team_id| actor.team_id == team_id.to_i }
    end

    describe "#match?" do
      let(:team_actor) { double('Actor', :team_id => 5) }
      let(:non_team_actor) { double('Actor', :team_id => 6) }

      it "returns true if block matches" do
        subject.match?(team_actor, "5").should eq(true)
      end

      it "returns false if block does not match" do
        subject.match?(non_team_actor, "5").should eq(false)
      end
    end
  end
end
