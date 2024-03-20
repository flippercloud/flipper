require 'flipper/adapters/redis'

RSpec.describe Flipper::Adapters::Redis do
  subject { described_class.new(client, key_prefix: key_prefix) }

  it_behaves_like "a redis adapter"
end
