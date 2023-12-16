require 'bundler/setup'
require 'flipper'
require 'stackprof'
require 'benchmark/ips'

flipper = Flipper.new(Flipper::Adapters::Memory.new)
feature = flipper.feature(:foo)
actor = Flipper::Actor.new("User;1")

profile = StackProf.run(mode: :wall, interval: 1_000) do
  2_000_000.times do
    feature.enabled?(actor)
  end
end

result = StackProf::Report.new(profile)
puts
result.print_text
puts "\n\n\n"
result.print_method(/Flipper::Feature#enabled?/)
