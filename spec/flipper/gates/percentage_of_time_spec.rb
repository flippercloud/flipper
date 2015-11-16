require 'helper'

RSpec.describe Flipper::Gates::PercentageOfTime do
  let(:feature_name) { :search }

  subject {
    described_class.new
  }
end
