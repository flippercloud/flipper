require 'ice_age'
require 'json'
require 'rack/test'
require 'rack/session'

module SpecHelpers
  extend self

  def self.included(base)
    base.let(:flipper) { build_flipper }
    base.let(:app) { build_app(flipper) }
  end

  def build_app(flipper, options = {})
    Flipper::UI.app(flipper, options) do |builder|
      builder.use Rack::Session::Cookie, secret: 'test' * 16 # Rack 3+ wants a 64-character secret
    end
  end

  def build_api(flipper, options = {})
    Flipper::Api.app(flipper, options)
  end

  def build_flipper(adapter = build_memory_adapter)
    Flipper.new(adapter)
  end

  def build_memory_adapter
    Flipper::Adapters::Memory.new
  end

  def json_response
    body = last_response.body
    if last_response["content-encoding"] == 'gzip'
      body = Flipper::Typecast.from_gzip(body)
    end
    JSON.parse(body)
  end

  def raw_api_get(path, query_string)
    status, headers, body = call_app(Rack::MockRequest.env_for(path, 'QUERY_STRING' => query_string))
    [status, headers, JSON.parse(body)]
  end

  # Rack 3.1 made rack.input optional; older Rack requires it.
  def call_without_rack_input(path, options = {})
    skip 'rack.input is required before Rack 3.1' if Gem::Version.new(Rack.release) < Gem::Version.new('3.1')

    env = Rack::MockRequest.env_for(path, options)
    env.delete('rack.input')
    call_app(env)
  end

  def call_app(env)
    status, headers, body = app.call(env)
    response_body = body.each_with_object(+'') { |part, buffer| buffer << part }
    [status, headers, response_body]
  ensure
    body.close if body.respond_to?(:close)
  end

  def api_error_code_reference_url
    'https://flippercloud.io/docs/api#error-code-reference'
  end

  def api_not_found_response
    {
      'code' => 1,
      'message' => 'Feature not found.',
      'more_info' => api_error_code_reference_url,
    }
  end

  def api_positive_percentage_error_response
    {
      'code' => 3,
      'message' => 'Percentage must be a positive number less than or equal to 100.',
      'more_info' => api_error_code_reference_url,
    }
  end

  def api_flipper_id_is_missing_response
    {
      'code' => 4,
      'message' => 'Required parameter flipper_id is missing.',
      'more_info' => api_error_code_reference_url,
    }
  end

  def api_expression_invalid_response
    {
      'code' => 7,
      'message' => 'The provided expression was not valid.',
      'more_info' => api_error_code_reference_url,
    }
  end

  def silence
    # Store the original stderr and stdout in order to restore them later
    original_stderr = $stderr
    original_stdout = $stdout

    # Redirect stderr and stdout
    $stderr = $stdout = StringIO.new

    yield
  ensure
    $stderr = original_stderr
    $stdout = original_stdout
  end

  def capture_output
    original_stderr = $stderr
    original_stdout = $stdout

    output = $stdout = $stderr = StringIO.new

    yield

    output.string
  ensure
    $stderr = original_stderr
    $stdout = original_stdout
  end
end

RSpec.configure do |config|
  config.order = :random
  Kernel.srand config.seed

  config.include Rack::Test::Methods
  config.include SpecHelpers
end
