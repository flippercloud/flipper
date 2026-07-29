require 'flipper/expression'

RSpec.describe Flipper::Expression do
  describe "#build" do
    it "can build Equal" do
      expression = described_class.build({
        "Equal" => [
          "basic",
          "basic",
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expression)
      expect(expression.function).to be(Flipper::Expressions::Equal)
      expect(expression.args).to eq([
        Flipper.constant("basic"),
        Flipper.constant("basic"),
      ])
    end

    it "can build GreaterThanOrEqualTo" do
      expression = described_class.build({
        "GreaterThanOrEqualTo" => [
          2,
          1,
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expression)
      expect(expression.function).to be(Flipper::Expressions::GreaterThanOrEqualTo)
      expect(expression.args).to eq([
        Flipper.constant(2),
        Flipper.constant(1),
      ])
    end

    it "can build GreaterThan" do
      expression = described_class.build({
        "GreaterThan" => [
          2,
          1,
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expression)
      expect(expression.function).to be(Flipper::Expressions::GreaterThan)
      expect(expression.args).to eq([
        Flipper.constant(2),
        Flipper.constant(1),
      ])
    end

    it "can build LessThanOrEqualTo" do
      expression = described_class.build({
        "LessThanOrEqualTo" => [
          2,
          1,
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expression)
      expect(expression.function).to be(Flipper::Expressions::LessThanOrEqualTo)
      expect(expression.args).to eq([
        Flipper.constant(2),
        Flipper.constant(1),
      ])
    end

    it "can build LessThan" do
      expression = described_class.build({
        "LessThan" => [2, 1]
      })

      expect(expression).to be_instance_of(Flipper::Expression)
      expect(expression.function).to be(Flipper::Expressions::LessThan)
      expect(expression.args).to eq([
        Flipper.constant(2),
        Flipper.constant(1),
      ])
    end

    it "can build NotEqual" do
      expression = described_class.build({
        "NotEqual" => [
          "basic",
          "plus",
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expression)
      expect(expression.function).to be(Flipper::Expressions::NotEqual)
      expect(expression.args).to eq([
        Flipper.constant("basic"),
        Flipper.constant("plus"),
      ])
    end

    it "can build Number" do
      expression = described_class.build(1)

      expect(expression).to be_instance_of(Flipper::Expression::Constant)
      expect(expression.value).to eq(1)
    end

    it "can build Percentage" do
      expression = described_class.build({
        "Percentage" => [1]
      })

      expect(expression).to be_instance_of(Flipper::Expression)
      expect(expression.function).to be(Flipper::Expressions::Percentage)
      expect(expression.args).to eq([Flipper.constant(1)])
    end

    it "can build PercentageOfActors" do
      expression = described_class.build({
        "PercentageOfActors" => [
          "User;1",
          40,
        ]
      })

      expect(expression).to be_instance_of(Flipper::Expression)
      expect(expression.function).to be(Flipper::Expressions::PercentageOfActors)
      expect(expression.args).to eq([
        Flipper.constant("User;1"),
        Flipper.constant(40),
      ])
    end

    it "can build String" do
      expression = described_class.build("basic")

      expect(expression).to be_instance_of(Flipper::Expression::Constant)
      expect(expression.value).to eq("basic")
    end

    it "can build Property" do
      expression = described_class.build({
        "Property" => ["flipper_id"]
      })

      expect(expression).to be_instance_of(Flipper::Expression)
      expect(expression.function).to be(Flipper::Expressions::Property)
      expect(expression.args).to eq([Flipper.constant("flipper_id")])
    end
  end

  describe "#eql?" do
    it "returns true for same class and args" do
      expression = described_class.build("foo")
      other = described_class.build("foo")
      expect(expression.eql?(other)).to be(true)
    end

    it "returns false for different class" do
      expression = described_class.build("foo")
      other = Object.new
      expect(expression.eql?(other)).to be(false)
    end

    it "returns false for different args" do
      expression = described_class.build("foo")
      other = described_class.build("bar")
      expect(expression.eql?(other)).to be(false)
    end
  end

  describe "#==" do
    it "returns true for same class and args" do
      expression = described_class.build("foo")
      other = described_class.build("foo")
      expect(expression == other).to be(true)
    end

    it "returns false for different class" do
      expression = described_class.build("foo")
      other = Object.new
      expect(expression == other).to be(false)
    end

    it "returns false for different args" do
      expression = described_class.build("foo")
      other = described_class.build("bar")
      expect(expression == other).to be(false)
    end
  end

  describe "#empty_groups?" do
    it "returns true for an empty group" do
      expect(described_class.build({"Any" => []}).empty_groups?).to be(true)
      expect(described_class.build({"All" => []}).empty_groups?).to be(true)
    end

    it "returns true for a nested empty group" do
      expression = described_class.build({
        "Any" => [{"Equal" => [{"Property" => ["plan"]}, "basic"]}, {"All" => []}],
      })
      expect(expression.empty_groups?).to be(true)
    end

    it "returns false for groups with conditions" do
      expression = described_class.build({
        "Any" => [{"All" => [{"Equal" => [{"Property" => ["plan"]}, "basic"]}]}],
      })
      expect(expression.empty_groups?).to be(false)
    end

    it "returns false for a condition" do
      expression = described_class.build({"Equal" => [{"Property" => ["plan"]}, "basic"]})
      expect(expression.empty_groups?).to be(false)
    end
  end

  describe "#prune_empty_groups" do
    let(:condition) { {"Equal" => [{"Property" => ["plan"]}, "basic"]} }

    it "returns nil when no conditions remain" do
      expect(described_class.build({"Any" => []}).prune_empty_groups).to be(nil)
      expect(described_class.build({"All" => []}).prune_empty_groups).to be(nil)
      expect(described_class.build({"Any" => [{"All" => []}]}).prune_empty_groups).to be(nil)
    end

    it "removes an empty All from an All parent" do
      expression = described_class.build({"All" => [condition, {"All" => []}]})
      expect(expression.prune_empty_groups).to eq(described_class.build({"All" => [condition]}))
    end

    it "removes an empty Any from an Any parent" do
      expression = described_class.build({"Any" => [condition, {"Any" => []}]})
      expect(expression.prune_empty_groups).to eq(described_class.build({"Any" => [condition]}))
    end

    it "keeps an empty Any inside an All because removal would broaden" do
      expression = described_class.build({"All" => [condition, {"Any" => []}]})
      expect(expression.prune_empty_groups).to eq(expression)
    end

    it "returns a condition untouched" do
      expression = described_class.build(condition)
      expect(expression.prune_empty_groups).to eq(expression)
    end
  end

  describe "#always_true?" do
    it "returns true for an empty All" do
      expect(described_class.build({"All" => []}).always_true?).to be(true)
    end

    it "returns true for an empty All inside an Any" do
      expression = described_class.build({
        "Any" => [{"Equal" => [{"Property" => ["plan"]}, "basic"]}, {"All" => []}],
      })
      expect(expression.always_true?).to be(true)
    end

    it "returns false for an empty Any" do
      expect(described_class.build({"Any" => []}).always_true?).to be(false)
    end

    it "returns false for conditional expressions" do
      expression = described_class.build({"Equal" => [{"Property" => ["plan"]}, "basic"]})
      expect(expression.always_true?).to be(false)
    end
  end
end
