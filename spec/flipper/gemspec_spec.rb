# Ruby moved these out of its default gems, so under Bundler `require` only finds
# them when a gem in the bundle declares them.
BUNDLED_GEM_LIBRARIES = %w[
  abbrev base64 benchmark bigdecimal csv drb fiddle getoptlong irb logger mutex_m
  nkf observer ostruct pstore racc rdoc readline reline resolv-replace rinda syslog
].freeze

RSpec.shared_examples "a gemspec declaring the bundled gems it requires" do
  it "declares the bundled gems its files require" do
    root = File.expand_path("../..", __dir__)
    required = spec.files.grep(/\.rb\z/).flat_map do |file|
      File.read(File.join(root, file)).scan(/^\s*require ['"]([\w-]+)['"]/).flatten
    end

    expect(required.uniq & BUNDLED_GEM_LIBRARIES - spec.runtime_dependencies.map(&:name)).to eq([])
  end
end

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

  it_behaves_like "a gemspec declaring the bundled gems it requires"
end

Dir[File.expand_path("../../flipper-*.gemspec", __dir__)].sort.each do |path|
  RSpec.describe File.basename(path) do
    let(:spec) { Gem::Specification.load(path) }

    it "packages only lib files" do
      expect(spec.files).not_to be_empty
      expect(spec.files).to all(start_with("lib/"))
    end

    it_behaves_like "a gemspec declaring the bundled gems it requires"
  end
end
