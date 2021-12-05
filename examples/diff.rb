require 'bundler/setup'
require_relative 'active_record/ar_setup'
require 'flipper'
require 'flipper/adapters/redis'
require 'flipper/adapters/active_record'

# Say you are using memory...
full_adapter = Flipper::Adapters::Memory.new
full_flipper = Flipper.new(full_adapter)

# And redis has some stuff enabled...
full_flipper.enable(:search)
full_flipper.enable_percentage_of_time(:verbose_logging, 5)
full_flipper.enable_percentage_of_actors(:new_feature, 5)
full_flipper.enable_actor(:issues, Flipper::Actor.new('1'))
full_flipper.enable_actor(:issues, Flipper::Actor.new('2'))
full_flipper.enable_group(:request_tracing, :staff)

# And you would like to switch to active record...
blank_adapter = Flipper::Adapters::Memory.new

diff = Flipper::Adapters::Sync::AdapterDiff.new(blank_adapter, full_adapter)
diff.operations.each do |operation|
  message = "Flipper[:#{operation.feature.key}].#{operation.name}"

  if operation.args.any?
    message << "("
    args = operation.args.map { |arg|
      case arg
      when Flipper::Actor
        arg.flipper_id.inspect
      else
        arg.inspect
      end
    }
    message << args.join(", ")
    message << ")"
  end

  puts message
end
