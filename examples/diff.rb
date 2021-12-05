require 'bundler/setup'
require 'flipper'

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

# output:
# Flipper[:search].enable
# Flipper[:verbose_logging].enable_percentage_of_time(5)
# Flipper[:new_feature].enable_percentage_of_actors(5)
# Flipper[:issues].enable_actor("1")
# Flipper[:issues].enable_actor("2")
# Flipper[:request_tracing].enable_group("staff")
# Flipper[:search].add
# Flipper[:verbose_logging].add
# Flipper[:new_feature].add
# Flipper[:issues].add
# Flipper[:request_tracing].add
