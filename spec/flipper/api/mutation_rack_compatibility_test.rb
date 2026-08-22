$LOAD_PATH.unshift File.expand_path('../../../lib', __dir__)

require 'json'
require 'minitest/autorun'
require 'pathname'
require 'rack/mock'
require 'flipper'
require 'flipper/api'

class MutationRackCompatibilityTest < Minitest::Test
  class RangeErrorInput
    def read(*)
      raise RangeError, 'adapter input failure'
    end

    def rewind
    end
  end

  class SecondReadRangeErrorInput
    attr_reader :reads

    def initialize(contents)
      @contents = contents
      @reads = 0
    end

    def read(*)
      @reads += 1
      raise RangeError, 'second-read adapter failure' if @reads > 1

      @contents
    end

    def rewind
    end
  end

  class SecondReadEOFInput < SecondReadRangeErrorInput
    def read(*)
      @reads += 1
      raise EOFError, 'second-read adapter failure' if @reads > 1

      @contents
    end
  end

  class ForwardOnlyInput
    def initialize(contents)
      @contents = contents
      @read = false
    end

    def read(*)
      return '' if @read

      @read = true
      @contents
    end
  end

  class FailingMultipartIO < StringIO
    def initialize(error_class)
      super()
      @error_class = error_class
    end

    def <<(*)
      raise @error_class, 'tempfile io failure'
    end
  end

  def setup
    @flipper = Flipper.new(Flipper::Adapters::Memory.new)
    @flipper[:existing].enable
    @app = Flipper::Api.app(@flipper)
    @baseline = adapter_state
  end

  def test_truncated_json_is_a_client_error_without_mutation
    assert_equal @baseline, adapter_state
    response = raw_request(
      '/features/existing/boolean',
      method: 'POST',
      input: '{"truncated":',
      'CONTENT_TYPE' => 'application/json'
    )

    assert_equal 400, response.first
    assert_equal @baseline, adapter_state
  end

  def test_non_object_json_root_is_a_client_error_without_mutation
    assert_equal @baseline, adapter_state
    response = raw_request(
      '/features/existing/boolean',
      method: 'POST',
      input: 'null',
      'CONTENT_TYPE' => 'application/json'
    )

    assert_equal 400, response.first
    assert_equal @baseline, adapter_state
  end

  def test_conflicting_form_shapes_are_a_client_error_without_mutation
    [
      'conflict=scalar&conflict[]=array',
      'conflict[]=array&conflict=scalar',
      'conflict=scalar&conflict[nested]=hash',
      'conflict[nested]=hash&conflict=scalar',
    ].each do |input|
      assert_equal @baseline, adapter_state, input
      response = raw_request(
        '/features/existing/boolean',
        method: 'POST',
        input: input,
        'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
      )

      assert_equal 400, response.first, input
      assert_equal @baseline, adapter_state, input
    end
  end

  def test_scalar_array_is_unprocessable_without_mutation
    assert_equal @baseline, adapter_state
    response = raw_request(
      '/features',
      method: 'POST',
      input: 'name[]=invalid',
      'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
    )

    assert_equal 422, response.first
    assert_equal @baseline, adapter_state
  end

  def test_json_content_type_with_charset_is_accepted
    response = raw_request(
      '/features',
      method: 'POST',
      input: JSON.generate(name: 'json_charset'),
      'CONTENT_TYPE' => 'application/json; charset=utf-8'
    )

    assert_equal 200, response.first
    assert_includes @flipper.features.map(&:key), 'json_charset'
  end

  def test_valid_multipart_scalar_is_accepted
    boundary = 'flipper-boundary'
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"name\"\r\n\r\n" \
      "valid_multipart\r\n" \
      "--#{boundary}--\r\n"
    response = raw_request(
      '/features',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )

    assert_equal 200, response.first
    assert_includes @flipper.features.map(&:key), 'valid_multipart'
  end

  def test_valid_multipart_framing_is_accepted
    boundary = 'flipper-boundary'
    body = "preamble\r\n--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"name\"\r\n\r\n" \
      "framed_multipart\r\n" \
      "--#{boundary}-- \t\r\nepilogue"
    response = raw_request(
      '/features',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )

    assert_equal 200, response.first
    assert_includes @flipper.features.map(&:key), 'framed_multipart'
  end

  def test_valid_multipart_transport_padding_is_accepted
    boundary = 'flipper-boundary'
    bodies = {
      'opening_padding' => "--#{boundary} \t\r\n" \
        "Content-Disposition: form-data; name=\"name\"\r\n\r\n" \
        "opening_padding\r\n" \
        "--#{boundary}--\r\n",
      'interpart_padding' => "--#{boundary}\r\n" \
        "Content-Disposition: form-data; name=\"ignored\"\r\n\r\n" \
        "value\r\n" \
        "--#{boundary} \t\r\n" \
        "Content-Disposition: form-data; name=\"name\"\r\n\r\n" \
        "interpart_padding\r\n" \
        "--#{boundary}--\r\n",
    }

    bodies.each do |name, body|
      response = raw_request(
        '/features',
        method: 'POST',
        input: body,
        'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
      )

      assert_equal 200, response.first, name
      assert_includes @flipper.features.map(&:key), name
    end
  end

  def test_json_query_and_body_shape_conflicts_are_client_errors_without_mutation
    assert_equal @baseline, adapter_state
    response = raw_request(
      '/features?name[]=query',
      method: 'POST',
      input: JSON.generate(name: 'created'),
      'CONTENT_TYPE' => 'application/json'
    )

    assert_equal 400, response.first
    assert_equal @baseline, adapter_state
  end

  def test_multipart_tempfile_factory_errors_remain_visible
    boundary = 'Aa'
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"upload\"; filename=\"file.txt\"\r\n" \
      "Content-Type: text/plain\r\n\r\ncontents\r\n" \
      "--#{boundary}--\r\n"
    env = Rack::MockRequest.env_for(
      '/features',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )
    env['rack.multipart.tempfile_factory'] = lambda do |*, **|
      raise ArgumentError, 'tempfile failure'
    end
    assert_equal @baseline, adapter_state

    error = assert_raises(ArgumentError) { @app.call(env) }

    assert_equal 'tempfile failure', error.message
    assert_equal @baseline, adapter_state
  end

  def test_multipart_tempfile_factory_is_called_once
    boundary = 'Aa'
    body = multipart_with_file(boundary, 'factory_once')
    env = Rack::MockRequest.env_for(
      '/features',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )
    calls = 0
    env['rack.multipart.tempfile_factory'] = lambda do |*, **|
      calls += 1
      StringIO.new
    end

    status, = @app.call(env)

    assert_equal 200, status
    assert_equal 1, calls
    assert_includes @flipper.features.map(&:key), 'factory_once'
  end

  def test_multipart_tempfile_factory_parser_shaped_errors_remain_visible
    [EOFError, RangeError].each do |error_class|
      boundary = 'Aa'
      body = multipart_with_file(boundary, 'unreachable')
      env = Rack::MockRequest.env_for(
        '/features',
        method: 'POST',
        input: body,
        'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
      )
      calls = 0
      env['rack.multipart.tempfile_factory'] = lambda do |*, **|
        calls += 1
        raise error_class, 'tempfile failure'
      end
      assert_equal @baseline, adapter_state

      error = assert_raises(error_class) { @app.call(env) }

      assert_equal 'tempfile failure', error.message
      assert_equal 1, calls
      assert_equal @baseline, adapter_state
    end
  end

  def test_multipart_tempfile_io_parser_shaped_errors_remain_visible
    [EOFError, RangeError].each do |error_class|
      boundary = 'Aa'
      body = multipart_with_file(boundary, 'unreachable')
      env = Rack::MockRequest.env_for(
        '/features',
        method: 'POST',
        input: body,
        'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
      )
      calls = 0
      env['rack.multipart.tempfile_factory'] = lambda do |*, **|
        calls += 1
        FailingMultipartIO.new(error_class)
      end
      assert_equal @baseline, adapter_state

      error = assert_raises(error_class) { @app.call(env) }

      assert_equal 'tempfile io failure', error.message
      assert_equal 1, calls
      assert_equal @baseline, adapter_state
    end
  end

  def test_forward_only_input_works_without_rewindable_middleware
    app = Flipper::Api.app(@flipper, use_rewindable_middleware: false)
    body = JSON.generate(name: 'forward_only')
    env = Rack::MockRequest.env_for(
      '/features',
      method: 'POST',
      input: '',
      'CONTENT_TYPE' => 'application/json'
    )
    env['rack.input'] = ForwardOnlyInput.new(body)
    env['CONTENT_LENGTH'] = body.bytesize.to_s

    status, = app.call(env)

    assert_equal 200, status
    assert_includes @flipper.features.map(&:key), 'forward_only'
  end

  def test_forward_only_malformed_import_is_a_client_error_without_rewindable_middleware
    app = Flipper::Api.app(@flipper, use_rewindable_middleware: false)
    body = '{'
    env = Rack::MockRequest.env_for(
      '/import',
      method: 'POST',
      input: '',
      'CONTENT_TYPE' => 'application/json'
    )
    env['rack.input'] = ForwardOnlyInput.new(body)
    env['CONTENT_LENGTH'] = body.bytesize.to_s
    assert_equal @baseline, adapter_state

    status, = app.call(env)

    assert_equal 422, status
    assert_equal @baseline, adapter_state
  end

  def test_body_io_range_errors_remain_visible
    assert_equal @baseline, adapter_state
    env = Rack::MockRequest.env_for(
      '/features/existing/boolean',
      method: 'POST',
      input: '',
      'CONTENT_TYPE' => 'application/json'
    )
    env['rack.input'] = RangeErrorInput.new

    error = assert_raises(RangeError) { @app.call(env) }

    assert_equal 'adapter input failure', error.message
    assert_equal @baseline, adapter_state
  end

  def test_validated_form_body_is_not_read_twice
    [SecondReadEOFInput, SecondReadRangeErrorInput].each do |input_class|
      app = Flipper::Api.app(@flipper, use_rewindable_middleware: false)
      body = "name=#{input_class.name.split('::').last}"
      input = input_class.new(body)
      env = Rack::MockRequest.env_for(
        '/features',
        method: 'POST',
        input: '',
        'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
      )
      env['rack.input'] = input
      env['CONTENT_LENGTH'] = body.bytesize.to_s

      status, = app.call(env)

      assert_equal 200, status, input_class.name
      assert_equal 1, input.reads, input_class.name
      assert_includes @flipper.features.map(&:key), input_class.name.split('::').last
    end
  end

  def test_invalid_query_encoding_is_a_client_error_without_mutation
    assert_equal @baseline, adapter_state
    response = raw_request(
      '/features/existing/boolean?ignored=%FF',
      method: 'POST',
      input: '{}',
      'CONTENT_TYPE' => 'application/json'
    )

    assert_equal 400, response.first
    assert_equal @baseline, adapter_state
  end

  def test_conflicting_query_shapes_are_a_client_error_without_mutation
    assert_equal @baseline, adapter_state
    response = raw_request(
      '/features/existing/boolean?conflict[]=array&conflict=scalar',
      method: 'POST',
      input: '',
      'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
    )

    assert_equal 400, response.first
    assert_equal @baseline, adapter_state
  end

  def test_multipart_boundary_errors_are_client_errors_without_mutation
    boundary = 'a' * 80
    assert_equal @baseline, adapter_state
    response = raw_request(
      '/features',
      method: 'POST',
      input: "--#{boundary}--\r\n",
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )

    assert_includes [400, 422], response.first
    assert_equal @baseline, adapter_state
  end

  def test_truncated_multipart_is_a_client_error_without_mutation
    assert_equal @baseline, adapter_state
    response = raw_request(
      '/features/existing/boolean',
      method: 'POST',
      input: "--Aa\r\nContent-Disposition: form-data; name=\"ignored\"\r\n\r\ntruncated",
      'CONTENT_TYPE' => 'multipart/form-data; boundary=Aa'
    )

    assert_equal 400, response.first
    assert_equal @baseline, adapter_state
  end

  private

  def raw_request(path, options)
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

  def multipart_with_file(boundary, name)
    "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"name\"\r\n\r\n" \
      "#{name}\r\n" \
      "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"upload\"; filename=\"file.txt\"\r\n" \
      "Content-Type: text/plain\r\n\r\ncontents\r\n" \
      "--#{boundary}--\r\n"
  end
end
