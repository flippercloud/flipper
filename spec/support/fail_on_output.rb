if ENV["CI"] || ENV["FAIL_ON_OUTPUT"]
  RSpec.configure do |config|
    config.around do |example|
      output = capture_output { example.run }
      fail "Use `silence { }` to avoid printing to STDOUT/STDERR\n#{output}" unless output.empty?
    end
  end
end
