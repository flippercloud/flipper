# Example showing poll interval being dynamically adjusted via poll-interval header
#
# Usage:
#   1. Terminal 1: bundle exec ruby examples/cloud/poll_interval/server.rb
#   2. Terminal 2: bundle exec ruby examples/cloud/poll_interval/client.rb

require 'bundler/setup'
require 'flipper'
require 'flipper/adapters/http'
require 'flipper/poller'
require 'logger'

# Setup logging to show what's happening
logger = Logger.new(STDOUT)
logger.level = Logger::INFO
logger.formatter = proc do |severity, datetime, progname, msg|
  "[#{datetime.strftime('%H:%M:%S')}] #{severity}: #{msg}\n"
end

# Create HTTP adapter pointing to localhost:3000
http_adapter = Flipper::Adapters::Http.new(url: 'http://localhost:3000/flipper')

# Create instrumenter to log poller events
instrumenter = Module.new do
  def self.instrument(name, payload = {})
    case payload[:operation]
    when :poll
      logger.info "Polling remote adapter..."
    when :shutdown_requested
      logger.warn "Shutdown requested by server via poll-shutdown header"
    when :stop
      logger.warn "Poller stopped"
    when :thread_start
      logger.info "Poller thread started"
    end

    result = yield if block_given?

    if payload[:operation] == :poll && result
      logger.info "Poll completed successfully"
    end

    result
  end

  def self.logger=(l)
    @logger = l
  end

  def self.logger
    @logger
  end
end
instrumenter.logger = logger

# Create poller with custom instrumenter and short initial interval
poller = Flipper::Poller.new(
  remote_adapter: http_adapter,
  interval: 5,  # Start with 5 second interval (will be enforced to 10 minimum)
  instrumenter: instrumenter,
  start_automatically: false,
  shutdown_automatically: false
)

logger.info "Starting poller with interval: #{poller.interval} seconds"
logger.info "Minimum allowed interval: #{Flipper::Poller::MINIMUM_POLL_INTERVAL} seconds"
logger.info ""
logger.info "Server can control polling via response headers:"
logger.info "  - poll-interval: <seconds>  (adjust poll frequency)"
logger.info "  - poll-shutdown: true       (stop polling)"
logger.info ""

# Track interval changes
last_interval = poller.interval

# Start the poller
poller.start

# Monitor for interval changes and log them
logger.info "Monitoring poller... (Ctrl+C to exit)"
logger.info ""

begin
  loop do
    sleep 2

    current_interval = poller.interval

    # Highlight when it changes
    if current_interval != last_interval
      logger.warn "⚠️  INTERVAL CHANGED: #{last_interval}s → #{current_interval}s"
      last_interval = current_interval
    end

    # Check if poller thread is still alive
    unless poller.thread&.alive?
      logger.warn "Poller thread is no longer running"
      break
    end
  end
rescue Interrupt
  logger.info ""
  logger.info "Interrupted by user"
ensure
  logger.info "Stopping poller..."
  poller.stop
  logger.info "Final interval: #{poller.interval} seconds"
end
