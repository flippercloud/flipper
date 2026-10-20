RSpec.describe "flipper-cloud.gemspec" do
  let(:spec) { Gem::Specification.load(File.expand_path("../../flipper-cloud.gemspec", __dir__)) }

  it "tells people who install the deprecated gem to use flipper instead" do
    expect(spec.post_install_message).to include("deprecated")
    expect(spec.post_install_message).to include("gem 'flipper'")
  end
end
