require './example_setup'

require 'flipper'
require 'flipper/adapters/memory'

adapter = Flipper::Adapters::Memory.new
flipper = Flipper.new(adapter)
logging = flipper[:logging]

perform_test = lambda do |number|
  logging.enable flipper.random(number)

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

  actual = (enabled.size / total.to_f * 100).round(2)

  # puts "#{enabled.size} / #{total}"
  puts "percentage: #{actual} vs #{number}"
end

[1, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 99, 100].each do |number|
  perform_test.call number
end
