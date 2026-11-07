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

  describe 'atomic snapshot installation' do
    subject { described_class.new }

    it 'does not advertise an atomic boundary without its mutex' do
      adapter = described_class.new({}, threadsafe: false)
      expect(adapter.supports?(:atomic_snapshot_install)).to eq(false)
      expect { adapter.apply_snapshot(Flipper::Snapshot.new(features: {})) }.to raise_error(NotImplementedError)
    end

    it 'owns nested input data and keeps its private floor out of exported snapshots' do
      data = {"search" => subject.default_config.merge(actors: Set["User;1"])}
      subject.apply_snapshot(Flipper::Snapshot.new(features: data, version: 10))
      data["search"][:actors].delete("User;1")
      data["search"][:actors].add("User;3")
      expect(subject.get_all["search"][:actors]).to eq(Set["User;1"])
      expect(subject.get_all_snapshot.version).to be_nil
    end

    it 'publishes neither partial data nor a floor after a failed reconciliation' do
      Flipper.new(subject).enable(:original)
      original = subject.get_all
      fail_install = true
      allow_any_instance_of(Flipper::Adapters::Sync::SnapshotApplier).to receive(:call).and_wrap_original do |method|
        result = method.call
        raise "failed after staging" if fail_install
        result
      end
      snapshot = Flipper::Snapshot.new(features: {}, version: 10)
      expect { subject.apply_snapshot(snapshot) }.to raise_error("failed after staging")
      expect(subject.get_all).to eq(original)
      fail_install = false
      expect(subject.apply_snapshot(Flipper::Snapshot.new(features: {}, version: 1))).to eq(:applied)
    end

    it 'explicitly imports unconditionally and resets the floor' do
      subject.apply_snapshot(Flipper::Snapshot.new(features: {}, version: 10))
      source = described_class.new
      Flipper.new(source).enable(:search)
      expect(subject.import(source)).to eq(true)
      expect(subject.get_all).to eq(source.get_all)
      expect(subject.apply_snapshot(Flipper::Snapshot.new(features: {}, version: 1))).to eq(:applied)
    end

    it 'lets instrumentation read the complete previous snapshot without re-locking' do
      Flipper.new(subject).enable(:original)
      previous = subject.get_all
      feature = Flipper::Feature.new(:original, subject)
      instrumenter = Flipper::Instrumenters::Memory.new
      allow(instrumenter).to receive(:instrument).and_wrap_original do |method, *args, &block|
        result = method.call(*args, &block)
        expect(subject.features).to eq(Set["original"])
        expect(subject.get(feature)).to eq(previous["original"])
        expect(subject.get_multi([feature])).to eq(previous)
        expect(subject.get_all_snapshot.features).to eq(previous)
        result
      end
      expect(subject.apply_snapshot(Flipper::Snapshot.new(features: {}, version: 10), instrumenter: instrumenter)).to eq(:applied)
      expect(subject.get_all).to eq({})
    end

    it 'rolls back when instrumentation raises before publication' do
      Flipper.new(subject).enable(:original)
      previous = subject.get_all
      instrumenter = Flipper::Instrumenters::Memory.new
      allow(instrumenter).to receive(:instrument).and_raise("subscriber failed")
      expect do
        subject.apply_snapshot(Flipper::Snapshot.new(features: {}, version: 10), instrumenter: instrumenter)
      end.to raise_error("subscriber failed")
      expect(subject.get_all).to eq(previous)
      expect(subject.apply_snapshot(Flipper::Snapshot.new(features: {}, version: 1))).to eq(:applied)
    end

    it 'rejects reentrant subscriber writes without changing the published state' do
      flipper = Flipper.new(subject)
      flipper.enable(:original)
      previous = subject.get_all
      instrumenter = Flipper::Instrumenters::Memory.new
      allow(instrumenter).to receive(:instrument) { flipper.enable(:subscriber_write) }
      expect do
        subject.apply_snapshot(Flipper::Snapshot.new(features: {}, version: 10), instrumenter: instrumenter)
      end.to raise_error(ThreadError)
      expect(subject.get_all).to eq(previous)
      expect(subject.apply_snapshot(Flipper::Snapshot.new(features: {}, version: 1))).to eq(:applied)
    end

    it 'rejects a delayed older response after a newer response has installed' do
      older_ready = Queue.new
      release_older = Queue.new
      older = Thread.new do
        snapshot = Flipper::Snapshot.new(features: {}, version: 9)
        older_ready << true
        release_older.pop
        subject.apply_snapshot(snapshot)
      end
      older_ready.pop
      data = {"search" => subject.default_config.merge(boolean: "true")}
      subject.apply_snapshot(Flipper::Snapshot.new(features: data, version: 10))
      release_older << true
      expect(older.value).to eq(:stale)
      expect(subject.get_all).to eq(data)
    ensure
      older&.kill if older&.alive?
      older&.join
    end

    it 'serializes overlapping installations through publication' do
      entered = Queue.new
      release = Queue.new
      newer_started = Queue.new
      allow_any_instance_of(Flipper::Adapters::Sync::SnapshotApplier).to receive(:call).and_wrap_original do |method|
        if Thread.current[:pause_install]
          entered << true
          release.pop
        end
        method.call
      end
      older = Thread.new do
        Thread.current[:pause_install] = true
        subject.apply_snapshot(Flipper::Snapshot.new(features: {}, version: 9))
      end
      entered.pop
      data = {"search" => subject.default_config.merge(boolean: "true")}
      newer = Thread.new do
        newer_started << true
        subject.apply_snapshot(Flipper::Snapshot.new(features: data, version: 10))
      end
      newer_started.pop
      release << true
      older.value
      expect(newer.value).to eq(:applied)
      expect(subject.get_all).to eq(data)
      expect(subject.apply_snapshot(Flipper::Snapshot.new(features: {}, version: 9))).to eq(:stale)
    ensure
      [older, newer].compact.each { |thread| thread.kill if thread.alive? }
      [older, newer].compact.each(&:join)
    end
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
