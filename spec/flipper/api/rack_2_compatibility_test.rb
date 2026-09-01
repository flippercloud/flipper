$LOAD_PATH.unshift File.expand_path('../../../lib', __dir__)

require 'json'
require 'minitest/autorun'
require 'pathname'
require 'rack/mock'
require 'flipper'
require 'flipper/api'

class Rack2CompatibilityTest < Minitest::Test
  MALFORMED_QUERIES = {
    'malformed percent escape' => 'keys=%',
    'conflicting parameter shapes' => 'a=1&a[]=2',
    'excessive nesting' => "a#{'[a]' * 150}=1",
  }.freeze

  def setup
    flipper = Flipper.new(Flipper::Adapters::Memory.new)
    flipper[:my_feature].enable
    @app = Flipper::Api.app(flipper)
  end

  def test_rack_2_parser_failures_fail_open
    assert_equal '2.0.9.4', Rack.release
    expected_response = raw_get('')

    MALFORMED_QUERIES.each do |description, query|
      response = raw_get(query)

      assert_equal 200, response.first, description
      assert_equal expected_response, response, description
    end
  end

  private

  def raw_get(query_string)
    env = Rack::MockRequest.env_for('/features', 'QUERY_STRING' => query_string)
    status, headers, body = @app.call(env)
    response_body = body.each_with_object(+'') { |part, buffer| buffer << part }
    [status, headers, JSON.parse(response_body)]
  ensure
    body.close if body.respond_to?(:close)
  end
end
