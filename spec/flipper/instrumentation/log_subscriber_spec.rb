require 'helper'
require 'flipper/adapters/memory'
require 'flipper/instrumentation/log_subscriber'

describe Flipper::Instrumentation::LogSubscriber do
  let(:adapter) { Flipper::Adapters::Memory.new }
  let(:flipper) {
    Flipper.new(adapter, :instrumenter => ActiveSupport::Notifications)
  }

  before do
    Flipper.register(:admins) { |thing|
      thing.respond_to?(:admin?) && thing.admin?
    }

    @io = StringIO.new
    logger = Logger.new(@io)
    logger.formatter = proc { |severity, datetime, progname, msg| "#{msg}\n" }
    described_class.logger = logger
  end

  after do
    described_class.logger = nil
  end

  let(:log) { @io.string }

  context "feature enabled checks" do
    before do
      clear_logs
      flipper[:search].enabled?
    end

    it "logs feature calls with result after operation" do
      feature_line = find_line('Flipper feature(search) enabled? false')
      feature_line.should include('[ thing=nil ]')
    end

    it "logs adapter calls" do
      adapter_line = find_line('Flipper feature(search) adapter(memory) read("search/boolean")')
      adapter_line.should include('[ result=nil ]')
    end

    it "logs gate calls" do
      gate_line = find_line('Flipper feature(search) gate(boolean) open? false')
      gate_line.should include('[ thing=nil ]')
    end
  end

  context "feature enabled checks with a thing" do
    let(:user) { Struct.new(:flipper_id).new('1') }

    before do
      clear_logs
      flipper[:search].enabled?(user)
    end

    it "logs thing for feature" do
      feature_line = find_line('Flipper feature(search) enabled?')
      feature_line.should include(user.inspect)
    end

    it "logs thing for gate" do
      gate_line = find_line('Flipper feature(search) gate(boolean) open')
      gate_line.should include(user.inspect)
    end
  end

  context "changing feature enabled state" do
    let(:user) { Struct.new(:flipper_id).new('1') }

    before do
      clear_logs
      flipper[:search].enable(user)
    end

    it "logs feature calls with result in brackets" do
      feature_line = find_line('Flipper feature(search) enable true')
      feature_line.should include("[ thing=#{user.inspect} gate_name=actor ]")
    end

    it "logs adapter value" do
      adapter_line = find_line('Flipper feature(search) adapter(memory) set_add("search/actors")')
      adapter_line.should include("value=#{user.flipper_id.to_s.inspect}")
    end

    it "logs adapter calls not related to a specific feature" do
      adapter_line = find_line('Flipper adapter(memory) set_add("features")')
      log.should_not include('Could not log')
      log.should_not include('NoMethodError: undefined method')
    end
  end

  def find_line(str)
    regex = /#{Regexp.escape(str)}/
    lines = log.split("\n")
    lines.detect { |line| line =~ regex } ||
      raise("Could not find line matching #{str.inspect} in #{lines.inspect}")
  end

  def clear_logs
    @io.string = ''
  end
end
