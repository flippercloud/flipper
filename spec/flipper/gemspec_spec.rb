RSpec.describe "flipper.gemspec" do
  let(:spec) { Gem::Specification.load(File.expand_path("../../flipper.gemspec", __dir__)) }

  it "packages only runtime files" do
    extra = spec.files.reject { |file| file.start_with?("lib/", "exe/") }
    expect(extra).to contain_exactly("Changelog.md", "LICENSE", "README.md")
  end

  it "packages the core library and executable but not adapter gem files" do
    expect(spec.files).to include("lib/flipper.rb", "lib/flipper/version.rb", "exe/flipper")
    expect(spec.files).not_to include("lib/flipper/adapters/redis.rb")
  end
end

Dir[File.expand_path("../../flipper-*.gemspec", __dir__)].sort.each do |path|
  RSpec.describe File.basename(path) do
    let(:spec) { Gem::Specification.load(path) }

    it "packages only lib files" do
      expect(spec.files).not_to be_empty
      expect(spec.files.reject { |file| file.start_with?("lib/") }).to eq([])
    end
  end
end
