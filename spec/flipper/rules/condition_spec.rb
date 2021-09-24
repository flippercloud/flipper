require 'helper'

RSpec.describe Flipper::Rules::Condition do
  let(:feature_name) { "search" }

  describe "#all" do
    it "wraps self with all" do
      rule = Flipper::Rules::Condition.new(
        {"type" => "Property", "value" => "flipper_id"},
        {"type" => "Operator", "value" => "eq"},
        {"type" => "String", "value" => "User;1"}
      )
      result = rule.all
      expect(result).to be_instance_of(Flipper::Rules::All)
      expect(result.rules).to eq([rule])
    end
  end

  describe "#any" do
    it "wraps self with any" do
      rule = Flipper::Rules::Condition.new(
        {"type" => "Property", "value" => "flipper_id"},
        {"type" => "Operator", "value" => "eq"},
        {"type" => "String", "value" => "User;1"}
      )
      result = rule.any
      expect(result).to be_instance_of(Flipper::Rules::Any)
      expect(result.rules).to eq([rule])
    end
  end

  describe "#value" do
    it "returns Hash with type and value" do
      rule = Flipper::Rules::Condition.new(
        {"type" => "Property", "value" => "flipper_id"},
        {"type" => "Operator", "value" => "eq"},
        {"type" => "String", "value" => "User;1"}
      )
      expect(rule.value).to eq({
        "type" => "Condition",
        "value" => {
          "left" => {"type" => "Property", "value" => "flipper_id"},
          "operator" => {"type" => "Operator", "value" => "eq"},
          "right" => {"type" => "String", "value" => "User;1"},
        },
      })
    end
  end

  describe "#eql?" do
    let(:rule) {
      Flipper::Rules::Condition.new(
        {"type" => "Property", "value" => "plan"},
        {"type" => "Operator", "value" => "eq"},
        {"type" => "String", "value" => "basic"}
      )
    }

    it "returns true if equal" do
      other_rule = Flipper::Rules::Condition.new(
        {"type" => "Property", "value" => "plan"},
        {"type" => "Operator", "value" => "eq"},
        {"type" => "String", "value" => "basic"}
      )
      expect(rule).to eql(other_rule)
      expect(rule == other_rule).to be(true)
    end

    it "returns false if not equal" do
      other_rule = Flipper::Rules::Condition.new(
        {"type" => "Property", "value" => "plan"},
        {"type" => "Operator", "value" => "eq"},
        {"type" => "String", "value" => "premium"}
      )
      expect(rule).not_to eql(other_rule)
      expect(rule == other_rule).to be(false)
    end

    it "returns false if not rule" do
      expect(rule).not_to eql(Object.new)
      expect(rule == Object.new).to be(false)
    end
  end

  describe "#matches?" do
    context "with no actor" do
      it "does not error for condition that returns true" do
        rule = Flipper::Rules::Condition.new(
          {"type" => "Boolean", "value" => true},
          {"type" => "Operator", "value" => "eq"},
          {"type" => "Boolean", "value" => true},
        )
        expect(rule.matches?(feature_name, nil)).to be(true)
      end

      it "does not error for condition that returns false" do
        rule = Flipper::Rules::Condition.new(
          {"type" => "Boolean", "value" => true},
          {"type" => "Operator", "value" => "eq"},
          {"type" => "Boolean", "value" => false},
        )
        expect(rule.matches?(feature_name, nil)).to be(false)
      end
    end

    context "with actor that does NOT respond to flipper_properties but does respond to flipper_id" do
      it "does not error" do
        user = Struct.new(:flipper_id).new("User;1")
        rule = Flipper::Rules::Condition.new(
          {"type" => "Boolean", "value" => true},
          {"type" => "Operator", "value" => "eq"},
          {"type" => "Boolean", "value" => true},
        )
        expect(rule.matches?(feature_name, user)).to be(true)
      end
    end

    context "with actor that does respond to flipper_properties but does NOT respond to flipper_id" do
      it "does not error" do
        user = Struct.new(:flipper_properties).new({"id" => 1, "type" => "User"})
        rule = Flipper::Rules::Condition.new(
          {"type" => "Boolean", "value" => true},
          {"type" => "Operator", "value" => "eq"},
          {"type" => "Boolean", "value" => true},
        )
        expect(rule.matches?(feature_name, user)).to be(true)
      end
    end

    context "with non-Flipper::Actor object that quacks like a duck" do
      it "works" do
        user_class = Class.new(Struct.new(:id, :flipper_properties)) do
          def flipper_id
            "User;#{id}"
          end
        end
        user = user_class.new(1, {})

        rule = Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "flipper_id"},
          {"type" => "Operator", "value" => "eq"},
          {"type" => "String", "value" => "User;1"}
        )
        expect(rule.matches?(feature_name, user)).to be(true)
        expect(rule.matches?(feature_name, user_class.new(2, {}))).to be(false)
      end
    end

    context "eq" do
      let(:rule) {
        Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "plan"},
          {"type" => "Operator", "value" => "eq"},
          {"type" => "String", "value" => "basic"}
        )
      }

      it "returns true when property matches" do
        actor = Flipper::Actor.new("User;1", {
          "plan" => "basic",
        })
        expect(rule.matches?(feature_name, actor)).to be(true)
      end

      it "returns false when property does not match" do
        actor = Flipper::Actor.new("User;1", {
          "plan" => "premium",
        })
        expect(rule.matches?(feature_name, actor)).to be(false)
      end
    end

    context "neq" do
      let(:rule) {
        Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "plan"},
          {"type" => "Operator", "value" => "neq"},
          {"type" => "String", "value" => "basic"}
        )
      }

      it "returns true when property does NOT match" do
        actor = Flipper::Actor.new("User;1", {
          "plan" => "premium",
        })
        expect(rule.matches?(feature_name, actor)).to be(true)
      end

      it "returns false when property does match" do
        actor = Flipper::Actor.new("User;1", {
          "plan" => "basic",
        })
        expect(rule.matches?(feature_name, actor)).to be(false)
      end
    end

    context "gt" do
      let(:rule) {
        Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "age"},
          {"type" => "Operator", "value" => "gt"},
          {"type" => "Integer", "value" => 20}
        )
      }

      it "returns true when property matches" do
        actor = Flipper::Actor.new("User;1", {
          "age" => 21,
        })
        expect(rule.matches?(feature_name, actor)).to be(true)
      end

      it "returns false when property does NOT match" do
        actor = Flipper::Actor.new("User;1", {
          "age" => 20,
        })
        expect(rule.matches?(feature_name, actor)).to be(false)
      end
    end

    context "gte" do
      let(:rule) {
        Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "age"},
          {"type" => "Operator", "value" => "gte"},
          {"type" => "Integer", "value" => 20}
        )
      }

      it "returns true when property matches" do
        actor = Flipper::Actor.new("User;1", {
          "age" => 20,
        })
        expect(rule.matches?(feature_name, actor)).to be(true)
      end

      it "returns false when property does NOT match" do
        actor = Flipper::Actor.new("User;1", {
          "age" => 19,
        })
        expect(rule.matches?(feature_name, actor)).to be(false)
      end
    end

    context "lt" do
      let(:rule) {
        Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "age"},
          {"type" => "Operator", "value" => "lt"},
          {"type" => "Integer", "value" => 21}
        )
      }

      it "returns true when property matches" do
        actor = Flipper::Actor.new("User;1", {
          "age" => 20,
        })
        expect(rule.matches?(feature_name, actor)).to be(true)
      end

      it "returns false when property does NOT match" do
        actor = Flipper::Actor.new("User;1", {
          "age" => 21,
        })
        expect(rule.matches?(feature_name, actor)).to be(false)
      end
    end

    context "lt with rand type" do
      let(:rule) {
        Flipper::Rules::Condition.new(
          {"type" => "Random", "value" => 100},
          {"type" => "Operator", "value" => "lt"},
          {"type" => "Integer", "value" => 25}
        )
      }

      it "returns true when property matches" do
        results = []
        (1..1000).to_a.each do |n|
          actor = Flipper::Actor.new("User;#{n}")
          results << rule.matches?(feature_name, actor)
        end

        enabled, disabled = results.partition { |r| r }
        expect(enabled.size).to be_within(30).of(250)
      end
    end

    context "lte" do
      let(:rule) {
        Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "age"},
          {"type" => "Operator", "value" => "lte"},
          {"type" => "Integer", "value" => 21}
        )
      }

      it "returns true when property matches" do
        actor = Flipper::Actor.new("User;1", {
          "age" => 21,
        })
        expect(rule.matches?(feature_name, actor)).to be(true)
      end

      it "returns false when property does NOT match" do
        actor = Flipper::Actor.new("User;1", {
          "age" => 22,
        })
        expect(rule.matches?(feature_name, actor)).to be(false)
      end
    end

    context "percentage" do
      let(:rule) {
        Flipper::Rules::Condition.new(
          {"type" => "Property", "value" => "flipper_id"},
          {"type" => "Operator", "value" => "percentage"},
          {"type" => "Integer", "value" => 25}
        )
      }

      it "returns true when property matches" do
        results = []
        (1..1000).to_a.each do |n|
          actor = Flipper::Actor.new("User;#{n}")
          results << rule.matches?(feature_name, actor)
        end

        enabled, disabled = results.partition { |r| r }
        expect(enabled.size).to be_within(10).of(250)
      end

      it "returns false when property does NOT match" do
        actor = Flipper::Actor.new("User;1")
        expect(rule.matches?(feature_name, actor)).to be(false)
      end
    end
  end
end
