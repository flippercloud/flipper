require "logger"
require "socket"
require "flipper/adapters/http"
require "flipper/adapters/poll"
require "flipper/poller"
require "flipper/adapters/dual_write"
require "flipper/adapters/sync/synchronizer"
require "flipper/cloud/memory_adapter"
require "flipper/cloud/shared_memory"
require "flipper/cloud/url_validator"
require "flipper/cloud/telemetry"
require "flipper/cloud/telemetry/instrumenter"
require "flipper/cloud/telemetry/submitter"

module Flipper
  module Cloud
    class Configuration
      # The set of valid ways that syncing can happpen.
      VALID_SYNC_METHODS = Set[
        :poll,
        :webhook,
      ].freeze

      DEFAULT_URL = "https://www.flippercloud.io/adapter".freeze

      # Seconds between polls when syncing by poll.
      DEFAULT_POLL_SYNC_INTERVAL = 10

      # Seconds between polls when syncing by webhook. Webhooks keep the local
      # adapter current; this slow poll only catches missed webhooks.
      DEFAULT_WEBHOOK_SYNC_INTERVAL = 300

      # Public: The token corresponding to an environment on flippercloud.io.
      attr_accessor :token

      # Public: The url for http adapter. Really should only be customized for
      #         development work if you are me and you are not me. Feel free to
      #         forget you ever saw this. Must be https so the cloud token is
      #         never transmitted in cleartext (local development uses https too).
      attr_reader :url

      # Public: net/http read timeout for all http requests (default: 5).
      attr_accessor :read_timeout

      # Public: net/http open timeout for all http requests (default: 5).
      attr_accessor :open_timeout

      # Public: net/http write timeout for all http requests (default: 5).
      attr_accessor :write_timeout

      # Public: IO stream to send debug output too. Off by default.
      #
      #  # for example, this would send all http request information to STDOUT
      #  configuration = Flipper::Cloud::Configuration.new
      #  configuration.debug_output = STDOUT
      attr_accessor :debug_output

      # Public: Instrumenter to use for the Flipper instance returned by
      #         Flipper::Cloud.new (default: Flipper::Instrumenters::Noop).
      #
      #  # for example, to use active support notifications you could do:
      #  configuration = Flipper::Cloud::Configuration.new
      #  configuration.instrumenter = ActiveSupport::Notifications
      attr_accessor :instrumenter

      # Public: Local adapter that is automatically kept in sync with cloud.
      # Reads go to it to keep latency low and resiliency high. When Cloud is
      # Flipper's default (Flipper::Cloud.set_default or the Rails engine),
      # reads go to a Memory adapter in front of it instead.
      #
      #  # for example, to use active record you could do:
      #  configuration = Flipper::Cloud::Configuration.new
      #  configuration.local_adapter = Flipper::Adapters::ActiveRecord.new
      attr_accessor :local_adapter

      # Public: Sets the Integer or Float number of seconds between attempts to
      # bring the local in sync with cloud.
      attr_writer :sync_interval

      # Public: The secret used to verify if syncs in the middleware should
      # occur or not.
      attr_accessor :sync_secret

      # Public: The logger to use for debugging inner workings.
      attr_accessor :logger

      # Public: Should the logger log or not (default: true).
      attr_accessor :logging_enabled

      # Public: The telemetry instance to use for tracking feature usage.
      attr_accessor :telemetry

      # Public: Should telemetry be enabled or not (default: false).
      attr_accessor :telemetry_enabled

      def initialize(options = {})
        setup_auth options
        setup_log options
        setup_http options
        setup_sync options
        setup_adapter options
        setup_telemetry options
      end

      # Public: Read or customize the http adapter. Calling without a block will
      # perform a read. Calling with a block yields the cloud adapter
      # for customization.
      #
      #   # for example, to instrument the http calls, you can wrap the http
      #   # adapter with the intsrumented adapter
      #   configuration = Flipper::Cloud::Configuration.new
      #   configuration.adapter do |adapter|
      #     Flipper::Adapters::Instrumented.new(adapter)
      #   end
      #
      def adapter(&block)
        if block_given?
          @adapter_block = block
        else
          @adapter_block.call app_adapter
        end
      end

      # Public: The Integer or Float number of seconds between attempts to bring
      # the local in sync with cloud (default: 10 when syncing by poll, 300
      # when syncing by webhook).
      def sync_interval
        @sync_interval || (sync_method == :webhook ? DEFAULT_WEBHOOK_SYNC_INTERVAL : DEFAULT_POLL_SYNC_INTERVAL)
      end

      # Public: Force a sync.
      def sync(cache_bust: false)
        remote = http_adapter
        return synchronize(remote, cache_bust: cache_bust) unless @memory

        # Fetch once for both the local adapter and memory.
        snapshot = Flipper::Adapters::Memory.new(remote.get_all(cache_bust: cache_bust))
        snapshot.sync_version = remote.sync_version
        sync_memory(snapshot)
      end

      # Public: The method that will be used to synchronize local adapter with
      # cloud. (default: :poll, will be :webhook if sync_secret is non-empty).
      def sync_method
        if !sync_secret || sync_secret.empty?
          :poll
        else
          :webhook
        end
      end

      # Internal: Returns true when reads are served from the Memory adapter
      # that every thread in the process shares.
      def memory_reads?
        !@memory.nil?
      end

      # Internal: The http client used by the http adapter. Exposed so we can
      # use the same client for posting telemetry.
      def http_client
        http_adapter.client
      end

      # Internal: Logs message if logging is enabled.
      def log(message, level: :debug)
        return unless logging_enabled
        logger.send(level, "name=flipper_cloud #{message}")
      end

      def instrument(name, payload = {}, &block)
        instrumenter.instrument(name, payload, &block)
      end

      def url=(value)
        @url = UrlValidator.validate(value)
      end

      private

      def app_adapter
        Flipper::Adapters::DualWrite.new(poll_adapter, http_adapter)
      end

      def synchronize(remote, options = {})
        Flipper::Adapters::Sync::Synchronizer.new(local_adapter, remote, {
          instrumenter: instrumenter,
        }.merge(options)).call
      end

      # Syncs the local adapter, where the version check uses the version other
      # processes share, then memory. Memory is updated even if the local
      # adapter fails, and the next sync writes the local adapter again.
      def sync_memory(snapshot)
        synchronize(snapshot)
      ensure
        import_memory(snapshot)
      end

      # The sync skips a snapshot older than the local adapter, which another
      # process synced, so memory takes the stored flags instead. It reads the
      # storage itself, because a use adapter such as a cache can be behind.
      def import_memory(snapshot)
        if snapshot.sync_version&.older_than?(@store.sync_version)
          @memory.import(@store)
        else
          @memory.import(snapshot)
        end
      rescue StandardError
        @memory.import(snapshot)
      end

      # Builds the adapter Flipper.configure would, with memory in front of its
      # storage for reads. Syncs go to the storage, and the adapters added with
      # use wrap both.
      def memory_adapter
        fill_memory
        # In webhook mode, other processes pick up a webhook's sync from the
        # local adapter.
        refresh_interval = DEFAULT_POLL_SYNC_INTERVAL if sync_method == :webhook
        @adapter_builder.wrap(MemoryAdapter.new(@store, @memory, refresh_interval: refresh_interval))
      end

      # Memory starts empty in each process. Fill it from the local adapter
      # until it has flags, so a Cloud outage at boot still has flags to read.
      def fill_memory
        return unless @memory.sync_version.nil? && @memory.features.empty?
        @memory.import(@store)
      rescue StandardError
        # The local adapter is down. Poll fills memory from Cloud instead.
      end

      def poller
        Flipper::Poller.get(@url + @token, {
          interval: sync_interval,
          remote_adapter: http_adapter,
          instrumenter: instrumenter,
        }).tap(&:start)
      end

      def poll_adapter
        poller = poller()
        return Flipper::Adapters::Poll.new(poller, local_adapter) unless @memory

        Flipper::Adapters::Poll.new(poller, memory_adapter, synchronizer: -> {
          sync_poll(poller.adapter)
        })
      end

      # Every thread's Poll calls this after each poll. Threads don't wait on
      # each other, so ones that read while a new version syncs sync it too.
      def sync_poll(snapshot)
        version = snapshot.sync_version
        return if @memory.synced?(version) && @store.sync_version == version

        @memory.sync(version) { sync_memory(snapshot) }
      rescue StandardError
        # Reads keep working from memory if the local adapter is down.
      end

      def http_adapter
        Flipper::Adapters::Http.new({
          url: @url,
          read_timeout: @read_timeout,
          open_timeout: @open_timeout,
          write_timeout: @write_timeout,
          max_retries: 0, # we'll handle retries ourselves
          debug_output: @debug_output,
          headers: {
            "flipper-cloud-token" => @token,
            "accept-encoding" => "gzip",
          },
        })
      end

      def setup_auth(options)
        set_option :token, options, required: true
      end

      def setup_log(options)
        set_option :logging_enabled, options, default: false, typecast: :boolean
        set_option :logger, options, from_env: false, default: -> {
          if logging_enabled
            Logger.new(STDOUT)
          else
            Logger.new("/dev/null")
          end
        }
      end

      def setup_http(options)
        set_option :url, options, default: DEFAULT_URL
        set_option :debug_output, options, from_env: false

        if @debug_output.nil? && Flipper::Typecast.to_boolean(ENV["FLIPPER_CLOUD_DEBUG_OUTPUT_STDOUT"])
          @debug_output = STDOUT
        end

        set_option :read_timeout, options, default: 5, typecast: :float, minimum: 0.1
        set_option :open_timeout, options, default: 2, typecast: :float, minimum: 0.1
        set_option :write_timeout, options, default: 5, typecast: :float, minimum: 0.1
      end

      def setup_sync(options)
        set_option :sync_secret, options

        # Left unset, sync_interval follows sync_method, which can change if
        # sync_secret is set after initialize.
        if options.key?(:sync_interval) || ENV.key?("FLIPPER_CLOUD_SYNC_INTERVAL")
          set_option :sync_interval, options, typecast: :float, minimum: 10
        end
      end

      def setup_adapter(options)
        set_option :local_adapter, options, default: -> { Adapters::Memory.new }, from_env: false
        # Internal: Flipper::Cloud.set_default passes the Memory adapter that
        # every thread shares and the Flipper::Configuration to build reads with.
        @memory = options[:memory]
        @adapter_builder = options[:adapter_builder]
        if @adapter_builder
          # One storage adapter: wrapped by the use adapters for syncs here,
          # and behind memory for reads in memory_adapter.
          @store = @adapter_builder.build_store
          self.local_adapter = @adapter_builder.wrap(@store)
        end
        @adapter_block = ->(adapter) { adapter }
      end

      def setup_telemetry(options)
        # Needs to be after url and token assignments because they are used for
        # uniqueness in Telemetry.instance_for.
        set_option :telemetry, options, from_env: false, default: -> {
          Telemetry.instance_for(self)
        }

        set_option :telemetry_enabled, options, default: true, typecast: :boolean
        instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
        @instrumenter = if telemetry_enabled
          Telemetry::Instrumenter.new(self, instrumenter)
        else
          instrumenter
        end
      end

      # Internal: Super helper for defining an option that can be set via
      # options hash or ENV with defaults, typecasting and minimums.
      def set_option(name, options, default: nil, typecast: nil, minimum: nil, from_env: true, required: false)
        env_var = "FLIPPER_CLOUD_#{name.to_s.upcase}"
        value = options.fetch(name) {
          default_value = default.respond_to?(:call) ? default.call : default
          if from_env
            ENV.fetch(env_var, default_value)
          else
            default_value
          end
        }
        value = Flipper::Typecast.send("to_#{typecast}", value) if typecast
        send("#{name}=", value)
        enforce_minimum(name, minimum) if minimum

        if required
          option_value = send(name)
          if option_value.nil? || option_value.empty?
            message = String.new("Flipper::Cloud #{name} is missing. Please ")
            message << "set #{env_var} or " if from_env
            message << "provide #{name} (e.g. Flipper::Cloud.new(#{name}: value))."
            raise ArgumentError, message
          end
        end
      end

      # Enforce minimum interval for tasks that run on a timer.
      def enforce_minimum(name, minimum)
        provided = send(name)
        if provided && provided < minimum
          warn "Flipper::Cloud##{name} must be at least #{minimum} seconds but was #{provided}. Using #{minimum} seconds."
          send(:instance_variable_set, "@#{name}", minimum)
        end
      end
    end
  end
end
