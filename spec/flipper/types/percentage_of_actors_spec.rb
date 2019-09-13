# frozen_string_literal: true

require 'helper'
require 'flipper/types/percentage_of_actors'

RSpec.describe Flipper::Types::PercentageOfActors do
  it_behaves_like 'a percentage'
end
