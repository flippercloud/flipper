require './example_setup'

require 'flipper'
require 'flipper/adapters/memory'

def perform_test(number)
  adapter = Flipper::Adapters::Memory.new
  logging = Flipper::Feature.new(:logging, adapter)
  percentage = Flipper::Types::PercentageOfRandom.new(number)
  logging.enable(percentage)

  total = 1_000
  enabled = []
  disabled = []

  (1..total).each do |number|
    if logging.enabled?
      enabled << number
    else
      disabled << number
    end
  end

  actual = ((enabled.size / total.to_f) * 100).round

  # puts "#{enabled.size} / #{total}"
  puts "percentage: #{actual} vs #{percentage.value}"
end

[1, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 99, 100].each do |number|
  perform_test(number)
end
