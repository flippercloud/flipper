require 'bundler/setup'
require 'flipper'
require 'stackprof'
require 'benchmark/ips'

flipper = Flipper.new(Flipper::Adapters::Memory.new)
actor = Flipper::Actor.new("User;1")

profile = StackProf.run(mode: :cpu, interval: 100) do
  1_000_000.times do
    flipper.enabled?(:foo, actor)
  end
end

result = StackProf::Report.new(profile)
puts
result.print_text
puts "\n\n\n"
result.print_method(/Class#new/)
puts "\n\n\n"
result.print_method(/gate_values/)
puts "\n\n\n"
result.print_method(/enabled?/)
puts "\n\n\n"
result.print_method(/GateValues/)
puts "\n\n\n"
