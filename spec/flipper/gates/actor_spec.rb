require 'helper'

RSpec.describe Flipper::Gates::Actor do
  let(:feature_name) { :search }

  subject {
    described_class.new
  }
end
