$LOAD_PATH.unshift File.expand_path('../../../lib', __dir__)

require 'json'
require 'minitest/autorun'
require 'pathname'
require 'rack/mock'
require 'flipper'
require 'flipper/api'

class MutationTransportCompatibilityTest < Minitest::Test
  def setup
    @flipper = Flipper.new(Flipper::Adapters::Memory.new)
    @flipper[:existing].enable
    @app = Flipper::Api.app(@flipper)
    @baseline = adapter_state
  end

  def test_malformed_json_is_rejected_without_mutation
    response = request(
      '/features',
      method: 'POST',
      input: '{"name":',
      'CONTENT_TYPE' => 'application/json'
    )

    assert_equal 400, response.first
    assert_equal @baseline, adapter_state
  end

  def test_non_object_json_is_rejected_without_mutation
    response = request(
      '/features',
      method: 'POST',
      input: '[]',
      'CONTENT_TYPE' => 'application/json'
    )

    assert_equal 400, response.first
    assert_equal @baseline, adapter_state
  end

  def test_query_json_shape_conflicts_are_rejected_without_mutation
    response = request(
      '/features?name[]=query',
      method: 'POST',
      input: JSON.generate(name: 'body'),
      'CONTENT_TYPE' => 'application/json'
    )

    assert_equal 400, response.first
    assert_equal @baseline, adapter_state
  end

  def test_scalar_containers_are_rejected_without_mutation
    response = request(
      '/features',
      method: 'POST',
      input: JSON.generate(name: ['invalid']),
      'CONTENT_TYPE' => 'application/json'
    )

    assert_equal 422, response.first
    assert_equal @baseline, adapter_state
  end

  def test_conflicting_form_shapes_are_rejected_in_either_order
    [
      'name=scalar&name[]=array',
      'name[]=array&name=scalar',
    ].each do |input|
      response = request(
        '/features',
        method: 'POST',
        input: input,
        'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
      )

      assert_equal 400, response.first
      assert_equal @baseline, adapter_state
    end
  end

  def test_excessively_nested_form_is_rejected_without_mutation
    input = "a#{'[a]' * 150}=1"
    response = request(
      '/features/existing/boolean',
      method: 'POST',
      input: input,
      'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
    )

    assert_equal 400, response.first
    assert_equal @baseline, adapter_state
  end

  def test_multipart_shape_conflicts_are_rejected_in_either_order
    [
      [['conflict', 'scalar'], ['conflict[]', 'array']],
      [['conflict[]', 'array'], ['conflict', 'scalar']],
    ].each do |fields|
      boundary = 'flipper-boundary'
      parts = fields.map do |name, value|
        "--#{boundary}\r\n" \
          "Content-Disposition: form-data; name=\"#{name}\"\r\n\r\n" \
          "#{value}\r\n"
      end
      response = request(
        '/features/existing/boolean',
        method: 'POST',
        input: "#{parts.join}--#{boundary}--\r\n",
        'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
      )

      assert_equal 400, response.first
      assert_equal @baseline, adapter_state
    end
  end

  def test_heterogeneous_multipart_array_elements_remain_valid
    boundary = 'flipper-boundary'
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"ignored[]\"\r\n\r\n" \
      "scalar\r\n--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"ignored[][nested]\"\r\n\r\n" \
      "value\r\n--#{boundary}--\r\n"
    response = request(
      '/features/existing/boolean',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )

    assert_equal 200, response.first
    assert @flipper[:existing].boolean_value
  end

  def test_excessively_nested_multipart_field_is_rejected_without_mutation
    boundary = 'flipper-boundary'
    name = "nested#{'[nested]' * 150}"
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"#{name}\"\r\n\r\n" \
      "value\r\n--#{boundary}--\r\n"
    response = request(
      '/features/existing/boolean',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )

    assert_equal 400, response.first
    assert_equal @baseline, adapter_state
  end

  def test_json_with_charset_remains_valid
    response = request(
      '/features',
      method: 'POST',
      input: JSON.generate(name: 'json_charset'),
      'CONTENT_TYPE' => 'application/json; charset=utf-8'
    )

    assert_equal 200, response.first
    assert_includes @flipper.features.map(&:key), 'json_charset'
  end

  private

  def request(path, options)
    env = Rack::MockRequest.env_for(path, options)
    status, headers, body = @app.call(env)
    response_body = body.each_with_object(+'') { |part, buffer| buffer << part }
    [status, headers, JSON.parse(response_body)]
  ensure
    body.close if body.respond_to?(:close)
  end

  def adapter_state
    Marshal.load(Marshal.dump(@flipper.adapter.get_all))
  end
end
