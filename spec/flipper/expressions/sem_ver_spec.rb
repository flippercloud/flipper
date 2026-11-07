RSpec.describe Flipper::Expressions::SemVer do
  describe "#call" do
    it "parses major, minor and patch" do
      version = described_class.call("2.3.1")
      expect(version.major).to eq(2)
      expect(version.minor).to eq(3)
      expect(version.patch).to eq(1)
      expect(version.prerelease).to eq([])
      expect(version.build).to eq([])
    end

    it "parses prerelease identifiers as numbers when numeric" do
      expect(described_class.call("1.0.0-beta.11").prerelease).to eq(["beta", 11])
    end

    it "parses build metadata" do
      expect(described_class.call("1.0.0+exp.sha.5114f85").build).to eq(["exp", "sha", "5114f85"])
    end

    it "fills in missing minor and patch with 0" do
      expect(described_class.call("2.3").to_s).to eq("2.3.0")
      expect(described_class.call("2").to_s).to eq("2.0.0")
    end

    it "allows a leading v" do
      expect(described_class.call("v2.3.1").to_s).to eq("2.3.1")
      expect(described_class.call("V2.3.1").to_s).to eq("2.3.1")
    end

    it "casts integers" do
      expect(described_class.call(2).to_s).to eq("2.0.0")
    end

    it "returns the version it was given" do
      version = described_class.call("2.3.1")
      expect(described_class.call(version)).to be(version)
    end

    it "returns nil for values that aren't versions" do
      [
        nil, true, {}, [], 2.3, -1, "", " 2.3.1", "2.3.1 ", "not a version", "01.2.3", "1.02.3",
        "1.2.3.4", "1.2.3-", "1.2.3-01", "1.2.3-alpha..1", "1.2.3+", "1.2.3+a..b", "vv1.2.3",
      ].each do |value|
        expect(described_class.call(value)).to be_nil, "expected #{value.inspect} to be nil"
      end
    end
  end

  describe "precedence" do
    def version(string)
      described_class.call(string)
    end

    it "orders the semver.org precedence example" do
      ordered = %w[
        1.0.0-alpha 1.0.0-alpha.1 1.0.0-alpha.beta 1.0.0-beta 1.0.0-beta.2
        1.0.0-beta.11 1.0.0-rc.1 1.0.0 2.0.0 2.1.0 2.1.1
      ]

      expect(ordered.map { |s| version(s) }.shuffle(random: Random.new(1)).sort.map(&:to_s)).to eq(ordered)
    end

    it "compares numbers numerically rather than as strings" do
      expect(version("2.10.0")).to be > version("2.9.0")
      expect(version("10.0.0")).to be > version("9.0.0")
    end

    it "ignores build metadata" do
      expect(version("1.0.0+a")).to eq(version("1.0.0+b"))
    end

    it "is not equal to strings" do
      expect(version("1.0.0")).not_to eq("1.0.0")
    end

    it "raises when compared with a non version" do
      expect { version("1.0.0") > "1.0.0" }.to raise_error(ArgumentError)
    end
  end

  describe "shared examples" do
    examples = Flipper::Typecast.from_json(FlipperRoot.join("spec/fixtures/expressions/SemVer.json").read)

    examples.fetch("valid").each do |example|
      it "evaluates #{Flipper::Typecast.to_json(example["expression"])} with #{Flipper::Typecast.to_json(example["context"] || {})}" do
        context = (example["context"] || {}).transform_keys(&:to_sym)
        result = Flipper::Expression.build(example["expression"]).evaluate(context)
        expect(example["result"]["enum"]).to include(result)
      end
    end
  end
end
