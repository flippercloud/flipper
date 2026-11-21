RSpec.describe Flipper::TestHelp do
  it "does not remove features from an instance memoized before configure" do
    app_adapter = Flipper::Adapters::Memory.new
    Flipper.configure do |config|
      config.adapter { app_adapter }
    end
    Flipper.enable(:checkout)

    described_class.flipper_configure
    described_class.flipper_reset

    expect(app_adapter.features).to eq(Set["checkout"])
  end
end
