require 'flipper/cloud/telemetry/backoff_policy'

RSpec.describe Flipper::Cloud::Telemetry::BackoffPolicy do
  context "#initialize" do
    it "with no options" do
      policy = described_class.new
      expect(policy.min_timeout_ms).to eq(30_000)
      expect(policy.max_timeout_ms).to eq(120_000)
      expect(policy.multiplier).to eq(1.5)
      expect(policy.randomization_factor).to eq(0.5)
    end

    it "with options" do
      policy = described_class.new({
        min_timeout_ms: 1234,
        max_timeout_ms: 5678,
        multiplier: 24,
        randomization_factor: 0.4,
      })
      expect(policy.min_timeout_ms).to eq(1234)
      expect(policy.max_timeout_ms).to eq(5678)
      expect(policy.multiplier).to eq(24)
      expect(policy.randomization_factor).to eq(0.4)
    end

    it "with min higher than max" do
      expect {
        described_class.new({
          min_timeout_ms: 2,
          max_timeout_ms: 1,
        })
      }.to raise_error(ArgumentError, ":min_timeout_ms (2) must be <= :max_timeout_ms (1)")
    end

    it "with invalid min_timeout_ms" do
      expect {
        described_class.new({
          min_timeout_ms: -1,
        })
      }.to raise_error(ArgumentError, ":min_timeout_ms must be >= 0 but was -1")
    end

    it "with invalid max_timeout_ms" do
      expect {
        described_class.new({
          max_timeout_ms: -1,
        })
      }.to raise_error(ArgumentError, ":max_timeout_ms must be >= 0 but was -1")
    end

    it "from env" do
      ENV.update(
        "FLIPPER_BACKOFF_MIN_TIMEOUT_MS" => "1000",
        "FLIPPER_BACKOFF_MAX_TIMEOUT_MS" => "2000",
        "FLIPPER_BACKOFF_MULTIPLIER" => "1.9",
        "FLIPPER_BACKOFF_RANDOMIZATION_FACTOR" => "0.1",
      )

      policy = described_class.new
      expect(policy.min_timeout_ms).to eq(1000)
      expect(policy.max_timeout_ms).to eq(2000)
      expect(policy.multiplier).to eq(1.9)
      expect(policy.randomization_factor).to eq(0.1)
    end
  end

  context "#next_interval" do
    it "works" do
      policy = described_class.new({
        min_timeout_ms: 1_000,
        max_timeout_ms: 10_000,
        multiplier: 2,
        randomization_factor: 0.5,
      })

      expect(policy.next_interval).to be_within(500).of(1000)
      expect(policy.next_interval).to be_within(1000).of(2000)
      expect(policy.next_interval).to be_within(2000).of(4000)
      expect(policy.next_interval).to be_within(4000).of(8000)
    end

    it "caps maximum duration at max_timeout_secs" do
      policy = described_class.new({
        min_timeout_ms: 1_000,
        max_timeout_ms: 10_000,
        multiplier: 2,
        randomization_factor: 0.5,
      })
      10.times { policy.next_interval }
      expect(policy.next_interval).to be_within(10_000*0.1).of(10_000)
    end
  end

  it "can reset" do
    policy = described_class.new({
      min_timeout_ms: 1_000,
      max_timeout_ms: 10_000,
      multiplier: 2,
      randomization_factor: 0.5,
    })
    10.times { policy.next_interval }

    expect(policy.attempts).to eq(10)
    policy.reset
    expect(policy.attempts).to eq(0)
  end
end
