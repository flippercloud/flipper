RSpec.describe Flipper::Expressions::Any do
  describe "#evaluate" do
    it "returns true if any args evaluate as true" do
      expression = described_class.new([
        Flipper.boolean(true),
        Flipper.string("yep").eq("nope"),
        Flipper.number(1).gte(10),
      ])
      expect(expression.evaluate).to be(true)
    end

    it "returns false if all args evaluate as false" do
      expression = described_class.new([
        Flipper.boolean(false),
        Flipper.string("yep").eq("nope"),
      ])
      expect(expression.evaluate).to be(false)
    end
  end

  describe "#any" do
    it "returns self" do
      expression = described_class.new([
        Flipper.boolean(true),
        Flipper.string("yep").eq("yep"),
      ])
      expect(expression.any).to be(expression)
    end
  end

  describe "#add" do
    it "returns new instance with expression added" do
      expression = described_class.new([Flipper.boolean(true)])
      other = Flipper.string("yep").eq("yep")

      result = expression.add(other)
      expect(result.args).to eq([
        Flipper.boolean(true),
        Flipper.string("yep").eq("yep"),
      ])
    end

    it "returns new instance with many expressions added" do
      expression = described_class.new([Flipper.boolean(true)])
      second = Flipper.string("yep").eq("yep")
      third = Flipper.number(1).lte(20)

      result = expression.add(second, third)
      expect(result.args).to eq([
        Flipper.boolean(true),
        Flipper.string("yep").eq("yep"),
        Flipper.number(1).lte(20),
      ])
    end

    it "returns new instance with array of expressions added" do
      expression = described_class.new([Flipper.boolean(true)])
      second = Flipper.string("yep").eq("yep")
      third = Flipper.number(1).lte(20)

      result = expression.add([second, third])
      expect(result.args).to eq([
        Flipper.boolean(true),
        Flipper.string("yep").eq("yep"),
        Flipper.number(1).lte(20),
      ])
    end
  end

  describe "#remove" do
    it "returns new instance with expression removed" do
      first = Flipper.boolean(true)
      second = Flipper.string("yep").eq("yep")
      third = Flipper.number(1).lte(20)
      expression = described_class.new([first, second, third])

      result = expression.remove(second)
      expect(expression.args).to eq([first, second, third])
      expect(result.args).to eq([first, third])
    end

    it "returns new instance with many expressions removed" do
      first = Flipper.boolean(true)
      second = Flipper.string("yep").eq("yep")
      third = Flipper.number(1).lte(20)
      expression = described_class.new([first, second, third])

      result = expression.remove(second, third)
      expect(expression.args).to eq([first, second, third])
      expect(result.args).to eq([first])
    end

    it "returns new instance with array of expressions removed" do
      first = Flipper.boolean(true)
      second = Flipper.string("yep").eq("yep")
      third = Flipper.number(1).lte(20)
      expression = described_class.new([first, second, third])

      result = expression.remove([second, third])
      expect(expression.args).to eq([first, second, third])
      expect(result.args).to eq([first])
    end
  end
end
