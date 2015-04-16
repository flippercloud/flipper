require 'helper'

describe Flipper::Gates::Group do
  let(:feature_name) { :search }

  subject {
    described_class.new
  }

  describe "#description" do
    context "with groups in set" do
      it "returns text" do
        values = Set['bacon', 'ham', "team\x1Eadmins"]
        subject.description(values).should eq('groups (:bacon, :ham, :team "admins")')
      end
    end

    context "with no groups in set" do
      it "returns disabled" do
        subject.description(Set.new).should eq('disabled')
      end
    end
  end

  describe "#open?" do
    context "with a group in adapter, but not registered" do
      before do
        Flipper.register(:staff) { |thing| true }
      end

      it "ignores group" do
        thing = Struct.new(:flipper_id).new('5')
        subject.open?(thing, Set[:newbs, :staff], feature_name: feature_name).should eq(true)
      end
    end

    context "thing that does not respond to method in group block" do
      before do
        Flipper.register(:stinkers) { |thing| thing.stinker? }
      end

      it "raises error" do
        expect {
          subject.open?(Object.new, Set[:stinkers], feature_name: feature_name)
        }.to raise_error(NoMethodError)
      end
    end

    context "with block parameter" do
      before do
        Flipper.register(:team) { |actor, team_id| actor.team_id == team_id }
      end

      it "passes the block parameter to the block" do
        thing = Struct.new(:team_id).new("admins")
        subject.open?(thing, Set["team\x1Eadmins"], feature_name: feature_name).should eq(true)
      end
    end
  end
end
