# For adapters that store the feature list under the key flipper_features,
# next to the feature data.
RSpec.shared_examples 'an adapter that protects its feature list' do
  it 'refuses writes to a feature named flipper_features' do
    subject.add(Flipper::Feature.new(:search, subject))
    feature = Flipper::Feature.new(:flipper_features, subject)
    boolean = feature.gate(:boolean)

    [
      -> { subject.add(feature) },
      -> { subject.enable(feature, boolean, Flipper::Types::Boolean.new(true)) },
      -> { subject.disable(feature, boolean, Flipper::Types::Boolean.new(false)) },
      -> { subject.clear(feature) },
      -> { subject.remove(feature) },
    ].each do |write|
      expect(write).to raise_error(ArgumentError, /"flipper_features" is reserved/)
    end

    expect(subject.features).to eq(Set["search"])
    expect(subject.get_all.keys).to eq(["search"])
  end
end
