# Simple test server for demonstrating poll interval changes
#
# Usage:
#   1. Terminal 1: bundle exec ruby examples/cloud/poll_interval/server.rb
#   2. Terminal 2: bundle exec ruby examples/cloud/poll_interval/client.rb
#
# Commands in server terminal:
#   - Type a number (e.g., "15") to set poll-interval header to that value
#   - Type "shutdown" to send poll-shutdown: true header
#   - Type "reset" to stop sending special headers
#   - Ctrl+C to exit

require 'bundler/setup'
require 'webrick'
require 'json'

# State for what headers to send
$poll_interval = nil
$poll_shutdown = false

# Thread to handle user input for changing headers
input_thread = Thread.new do
  puts ""
  puts "=" * 60
  puts "Server Controls:"
  puts "  Type a number (e.g., '15') to set poll-interval"
  puts "  Type 'shutdown' to trigger poll shutdown"
  puts "  Type 'reset' to clear all special headers"
  puts "=" * 60
  puts ""

  loop do
    print "> "
    input = gets&.chomp
    break if input.nil?

    case input
    when /^\d+$/
      $poll_interval = input.to_i
      puts "✓ Will send poll-interval: #{$poll_interval}"
    when "shutdown"
      $poll_shutdown = true
      puts "✓ Will send poll-shutdown: true"
    when "reset"
      $poll_interval = nil
      $poll_shutdown = false
      puts "✓ Cleared all special headers"
    else
      puts "Unknown command. Use a number, 'shutdown', or 'reset'"
    end
  end
end

# Setup WEBrick server
server = WEBrick::HTTPServer.new(
  Port: 3000,
  Logger: WEBrick::Log.new($stdout, WEBrick::Log::INFO),
  AccessLog: [[
    $stdout,
    WEBrick::AccessLog::COMMON_LOG_FORMAT
  ]]
)

# Handle GET /flipper/features
server.mount_proc '/flipper/features' do |req, res|
  # Build response
  response_body = {
    features: []
  }

  res.status = 200
  res['Content-Type'] = 'application/json'
  res.body = JSON.generate(response_body)

  # Add special headers if configured
  if $poll_interval
    res['poll-interval'] = $poll_interval.to_s
    puts "→ Sent poll-interval: #{$poll_interval}"
  end

  if $poll_shutdown
    res['poll-shutdown'] = 'true'
    puts "→ Sent poll-shutdown: true"
  end
end

# Trap interrupt and shutdown gracefully
trap('INT') do
  puts "\nShutting down server..."
  server.shutdown
  input_thread.kill
end

puts "Server starting on http://localhost:3000"
puts "Endpoint: GET http://localhost:3000/flipper/features"
puts ""

server.start
