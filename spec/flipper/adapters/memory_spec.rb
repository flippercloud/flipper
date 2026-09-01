require "open3"
require "rbconfig"

RSpec.describe Flipper::Adapters::Memory do
  let(:source) { {} }

  context 'threadsafe: true' do
    subject { described_class.new(source, threadsafe: true) }

    it_should_behave_like 'a flipper adapter'
  end

  context 'threadsafe: false' do
    subject { described_class.new(source, threadsafe: false) }

    it_should_behave_like 'a flipper adapter'
  end

  it "can initialize from big hash" do
    flipper = Flipper.new(subject)
    flipper.enable :subscriptions
    flipper.disable :search
    flipper.enable_percentage_of_actors :pro_deal, 20
    flipper.enable_percentage_of_time :logging, 30
    flipper.enable_actor :following, Flipper::Actor.new('1')
    flipper.enable_actor :following, Flipper::Actor.new('3')
    flipper.enable_group :following, Flipper::Types::Group.new(:staff)

    dup = described_class.new(subject.get_all)

    expect(dup.get_all).to eq({
      "subscriptions" => subject.default_config.merge(boolean: "true"),
      "search" => subject.default_config,
      "logging" => subject.default_config.merge(:percentage_of_time => "30"),
      "pro_deal" => subject.default_config.merge(:percentage_of_actors => "20"),
      "following" => subject.default_config.merge(actors: Set["1", "3"], groups: Set["staff"]),
    })
  end

  it "uses its inherited Mutex safely after a fork" do
    skip "Process.fork is not supported" unless Process.respond_to?(:fork)

    script = <<~'RUBY'
      require "flipper"

      adapter = Flipper::Adapters::Memory.new({}, threadsafe: true)
      mutex = adapter.instance_variable_get(:@lock)
      raise "memory adapter does not use Mutex" unless mutex.instance_of?(Mutex)

      locked = Queue.new
      release = Queue.new
      holder = Thread.new do
        mutex.lock
        locked << true
        release.pop
        mutex.unlock
      end
      locked.pop

      begin
        child_pid = fork do
          begin
            adapter.features
            exit! 0
          rescue => error
            warn error.message
            exit! 1
          end
        end

        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2
        status = nil
        until status
          if result = Process.wait2(child_pid, Process::WNOHANG)
            _, status = result
          elsif Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
            Process.kill("KILL", child_pid)
            Process.wait(child_pid)
            raise "forked child timed out"
          else
            sleep 0.01
          end
        end
      ensure
        release << true
        holder.join(1)
      end

      exit(status.success? ? 0 : 1)
    RUBY

    _, stderr, status = Open3.capture3(
      RbConfig.ruby,
      "-Ilib",
      "-e",
      script,
      chdir: File.expand_path("../../..", __dir__)
    )

    expect(status).to be_success, stderr
  end
end
