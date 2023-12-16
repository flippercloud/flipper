class FakeBackoffPolicy
  def initialize
    @retries = 0
  end

  attr_reader :retries

  def next_interval
    @retries += 1
    0
  end

  def reset
  end
end
