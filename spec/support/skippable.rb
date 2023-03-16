RSpec.configure do |config|
  config.before(:all) do
    $skip = false
  end

  def skip_on_error(error, message, &block)
    # Premptively skip if we've already skipped
    skip(message) if $skip
    block.call
  rescue error
    if ENV["CI"]
      raise
    else
      $skip = true
      skip(message)
    end
  end
end
