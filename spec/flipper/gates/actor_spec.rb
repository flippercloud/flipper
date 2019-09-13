# frozen_string_literal: true

require 'helper'

RSpec.describe Flipper::Gates::Actor do
  subject do
    described_class.new
  end

  let(:feature_name) { :search }
end
