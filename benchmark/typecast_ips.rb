require 'bundler/setup'
require 'flipper'
require 'benchmark/ips'

Benchmark.ips do |x|
  x.report("Typecast.to_boolean true") { Flipper::Typecast.to_boolean(true) }
  x.report("Typecast.to_boolean 1") { Flipper::Typecast.to_boolean(1) }
  x.report("Typecast.to_boolean 'true'") { Flipper::Typecast.to_boolean('true'.freeze) }
  x.report("Typecast.to_boolean '1'") { Flipper::Typecast.to_boolean('1'.freeze) }
  x.report("Typecast.to_boolean false") { Flipper::Typecast.to_boolean(false) }

  x.report("Typecast.to_integer 1") { Flipper::Typecast.to_integer(1) }
  x.report("Typecast.to_integer '1'") { Flipper::Typecast.to_integer('1') }

  x.report("Typecast.to_float 1") { Flipper::Typecast.to_float(1) }
  x.report("Typecast.to_float '1'") { Flipper::Typecast.to_float('1'.freeze) }
  x.report("Typecast.to_float 1.01") { Flipper::Typecast.to_float(1) }
  x.report("Typecast.to_float '1.01'") { Flipper::Typecast.to_float('1'.freeze) }
end
