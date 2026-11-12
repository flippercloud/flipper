# Regression: ISSUE-001 — Flipper.<name> briefly undefined while configuration is replaced
# Found by /qa on 2026-11-12
# Report: .nunebot/qa/qa-report-named-instances-2026-11-12.md
RSpec.describe "named Flipper instances accessor during configuration replacement" do
  it "keeps an accessor defined when the new configuration has the same name" do
    Flipper.configure { |config| config.named(:cross_app) }
    removed = []
    Flipper.define_singleton_method(:singleton_method_removed) { |name| removed << name }

    begin
      replacement = Flipper::Configuration.new
      replacement.named(:cross_app)
      Flipper.configuration = replacement
    ensure
      Flipper.singleton_class.send(:remove_method, :singleton_method_removed)
    end

    expect(removed).not_to include(:cross_app)
    expect(Flipper.cross_app.instance).to be_a(Flipper::DSL)
  end

  it "still removes accessors for names the new configuration drops" do
    Flipper.configure { |config| config.named(:cross_app) }

    Flipper.configuration = Flipper::Configuration.new

    expect(Flipper).not_to respond_to(:cross_app)
  end
end
