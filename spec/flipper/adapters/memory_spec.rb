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

  it "synchronizes safely after a fork" do
    adapter = described_class.new(source, threadsafe: true)
    fork_safe_mutex = adapter.instance_variable_get(:@lock)
    original = fork_safe_mutex.mutex
    locked = Queue.new
    release = Queue.new
    thread = Thread.new do
      original.lock
      locked << true
      release.pop
      original.unlock
    end

    locked.pop
    allow(Process).to receive(:pid).and_return(Process.pid + 1)

    expect { adapter.features }.not_to raise_error
    expect(fork_safe_mutex.mutex).not_to equal(original)
  ensure
    release << true if release
    thread&.join
  end
end
