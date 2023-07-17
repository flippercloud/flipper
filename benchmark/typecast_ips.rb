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

  x.report("Typecast.to_number 1") { Flipper::Typecast.to_number(1) }
  x.report("Typecast.to_number 1.1") { Flipper::Typecast.to_number(1.1) }
  x.report("Typecast.to_number '1'") { Flipper::Typecast.to_number('1'.freeze) }
  x.report("Typecast.to_number '1.1'") { Flipper::Typecast.to_number('1.1'.freeze) }
  x.report("Typecast.to_number nil") { Flipper::Typecast.to_number(nil) }
  time = Time.now
  x.report("Typecast.to_number Time.now") { Flipper::Typecast.to_number(time) }
end
