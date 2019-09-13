# frozen_string_literal: true

require 'helper'
require 'flipper/types/percentage_of_time'

RSpec.describe Flipper::Types::PercentageOfTime do
  it_behaves_like 'a percentage'
end
