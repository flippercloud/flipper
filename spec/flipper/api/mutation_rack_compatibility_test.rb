$LOAD_PATH.unshift File.expand_path('../../../lib', __dir__)

require 'json'
require 'minitest/autorun'
require 'pathname'
require 'rack/mock'
require 'rack/tempfile_reaper'
require 'tempfile'
require 'flipper'
require 'flipper/api'

class MutationRackCompatibilityTest < Minitest::Test
  class FailingEnableAdapter < Flipper::Adapters::Memory
    def enable(*)
      raise 'adapter down'
    end
  end

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

  class CloseFailingMultipartIO < StringIO
    attr_reader :close_calls

    def initialize
      super
      @close_calls = 0
    end

    def close
      @close_calls += 1
      raise 'close down'
    end

    def force_close
      StringIO.instance_method(:close).bind(self).call
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

  def test_valid_quoted_multipart_boundary_preserves_leading_space
    boundary = ' Aa'
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"name\"\r\n\r\n" \
      "leading_space_boundary\r\n" \
      "--#{boundary}--\r\n"
    response = raw_request(
      '/features',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => "multipart/form-data; xboundary=wrong; boundary = \"#{boundary}\""
    )

    assert_equal 200, response.first
    assert_includes @flipper.features.map(&:key), 'leading_space_boundary'
  end

  def test_valid_folded_multipart_disposition_is_accepted
    boundary = 'Aa'
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data;\r\n name=\"name\"\r\n\r\n" \
      "folded_disposition\r\n" \
      "--#{boundary}--\r\n"
    response = raw_request(
      '/features',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )

    assert_equal 200, response.first
    assert_includes @flipper.features.map(&:key), 'folded_disposition'
  end

  def test_non_form_data_multipart_disposition_is_rejected_without_mutation
    boundary = 'Aa'
    body = "--#{boundary}\r\n" \
      "Content-Disposition: attachment; name=\"name\"\r\n\r\n" \
      "attached\r\n" \
      "--#{boundary}--\r\n"
    assert_equal @baseline, adapter_state

    response = raw_request(
      '/features',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )

    assert_equal 400, response.first
    assert_equal @baseline, adapter_state
  end

  def test_multipart_labeled_import_is_rejected_without_mutation
    body = JSON.generate(features: {created: {boolean: 'true'}})
    assert_equal @baseline, adapter_state

    response = raw_request(
      '/import',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => 'multipart/form-data; boundary=Aa'
    )

    assert_equal 400, response.first
    assert_equal @baseline, adapter_state
  end

  def test_form_values_preserve_literal_semicolons
    response = raw_request(
      '/features',
      method: 'POST',
      input: 'name=semi;colon',
      'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
    )

    assert_equal 200, response.first
    assert_includes @flipper.features.map(&:key), 'semi;colon'
    refute_includes @flipper.features.map(&:key), 'semi'
  end

  def test_form_values_apply_racks_terminal_nul_normalization
    response = raw_request(
      '/features/nul_actor/actors',
      method: 'POST',
      input: "flipper_id=User%3B123\0",
      'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
    )

    assert_equal 200, response.first
    assert_includes @flipper[:nul_actor].actors_value, 'User;123'
    refute_includes @flipper[:nul_actor].actors_value, "User;123\0"
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

  def test_duplicate_json_members_are_client_errors_without_mutation
    [
      '{"name":[],"name":"created"}',
      '{"name":"created","name":[]}',
    ].each do |body|
      assert_equal @baseline, adapter_state, body
      response = raw_request(
        '/features',
        method: 'POST',
        input: body,
        'CONTENT_TYPE' => 'application/json'
      )

      assert_equal 400, response.first, body
      assert_equal @baseline, adapter_state, body
    end
  end

  def test_duplicate_import_members_are_client_errors_without_mutation
    [
      '{"features":{"bad":{"boolean":[],"boolean":"true"}}}',
      '{"features":{"bad":{"boolean":"true","boolean":[]}}}',
    ].each do |body|
      assert_equal @baseline, adapter_state, body
      response = raw_request(
        '/import',
        method: 'POST',
        input: body,
        'CONTENT_TYPE' => 'application/json'
      )

      assert_equal 422, response.first, body
      assert_equal @baseline, adapter_state, body
    end
  end

  def test_invalid_actor_percentage_expressions_do_not_mutate_state
    [-1, 200, 'not-a-number'].each do |percentage|
      expression = {PercentageOfActors: [{Property: ['flipper_id']}, percentage]}
      assert_equal @baseline, adapter_state, percentage.inspect

      direct_response = raw_request(
        '/features/bad/expression',
        method: 'POST',
        input: JSON.generate(expression),
        'CONTENT_TYPE' => 'application/json'
      )
      import_response = raw_request(
        '/import',
        method: 'POST',
        input: JSON.generate(features: {bad: {expression: expression}}),
        'CONTENT_TYPE' => 'application/json'
      )

      assert_equal 422, direct_response.first, percentage.inspect
      assert_equal 422, import_response.first, percentage.inspect
      assert_equal @baseline, adapter_state, percentage.inspect
    end
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

  def test_multipart_tempfiles_close_with_the_response
    boundary = 'Aa'
    env = Rack::MockRequest.env_for(
      '/features',
      method: 'POST',
      input: multipart_with_file(boundary, 'reaped_upload'),
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )
    app = Rack::TempfileReaper.new(@app)

    status, _, response_body = app.call(env)
    tempfile = env.fetch('rack.request.form_hash').fetch('upload').fetch(:tempfile)

    assert_equal 200, status
    refute tempfile.closed?
    response_body.close
    assert tempfile.closed?
  ensure
    response_body.close if response_body && tempfile && !tempfile.closed?
  end

  def test_rejected_multipart_tempfiles_close_with_the_response
    boundary = 'Aa'
    body = multipart_with_file(boundary, 'unreachable')
    env = Rack::MockRequest.env_for(
      '/features/existing/boolean?upload=scalar',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )
    tempfiles = []
    env['rack.multipart.tempfile_factory'] = lambda do |*, **|
      tempfile = Tempfile.new('flipper-upload')
      tempfiles << tempfile
      tempfile
    end
    app = Rack::TempfileReaper.new(@app)
    assert_equal @baseline, adapter_state

    status, _, response_body = app.call(env)

    assert_equal 400, status
    assert_equal 1, tempfiles.length
    refute tempfiles.first.closed?
    assert_equal @baseline, adapter_state
    response_body.close
    assert tempfiles.first.closed?
  ensure
    response_body.close if response_body && tempfiles.any? { |tempfile| !tempfile.closed? }
    tempfiles.each { |tempfile| tempfile.close! unless tempfile.closed? }
  end

  def test_multipart_tempfiles_close_when_the_adapter_raises
    flipper = Flipper.new(FailingEnableAdapter.new)
    app = Rack::TempfileReaper.new(Flipper::Api.app(flipper))
    boundary = 'Aa'
    env = Rack::MockRequest.env_for(
      '/features/target/boolean',
      method: 'POST',
      input: multipart_with_file(boundary, 'ignored'),
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )
    tempfiles = []
    env['rack.multipart.tempfile_factory'] = lambda do |*, **|
      tempfile = Tempfile.new('flipper-upload')
      tempfiles << tempfile
      tempfile
    end

    error = assert_raises(RuntimeError) { app.call(env) }

    assert_equal 'adapter down', error.message
    assert_equal 1, tempfiles.length
    assert tempfiles.first.closed?
    assert_empty env['rack.tempfiles']
  ensure
    tempfiles.each { |tempfile| tempfile.close! unless tempfile.closed? }
  end

  def test_multipart_cleanup_preserves_adapter_error_and_attempts_every_close
    flipper = Flipper.new(FailingEnableAdapter.new)
    app = Rack::TempfileReaper.new(Flipper::Api.app(flipper))
    boundary = 'Aa'
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"upload_one\"; filename=\"one.txt\"\r\n" \
      "Content-Type: text/plain\r\n\r\none\r\n" \
      "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"upload_two\"; filename=\"two.txt\"\r\n" \
      "Content-Type: text/plain\r\n\r\ntwo\r\n" \
      "--#{boundary}--\r\n"
    env = Rack::MockRequest.env_for(
      '/features/target/boolean',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )
    tempfiles = []
    env['rack.multipart.tempfile_factory'] = lambda do |*, **|
      CloseFailingMultipartIO.new.tap { |tempfile| tempfiles << tempfile }
    end

    error = assert_raises(RuntimeError) { app.call(env) }

    assert_equal 'adapter down', error.message
    assert_equal 2, tempfiles.length
    assert_equal [1, 1], tempfiles.map(&:close_calls)
    assert_empty env['rack.tempfiles']
  ensure
    tempfiles.each(&:force_close)
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
    {
      'overlong' => ['a' * 71, nil],
      'invalid character' => ['a@b', nil],
      'trailing space' => ['Aa ', nil],
      'duplicate parameter' => ['Aa', 'Bb'],
    }.each do |description, (boundary, duplicate)|
      content_type = "multipart/form-data; boundary=\"#{boundary}\""
      content_type << "; boundary=#{duplicate}" if duplicate
      assert_equal @baseline, adapter_state, description
      response = raw_request(
        '/features/existing/boolean',
        method: 'POST',
        input: "--#{boundary}--\r\n",
        'CONTENT_TYPE' => content_type
      )

      assert_equal 400, response.first, description
      assert_equal @baseline, adapter_state, description
    end
  end

  def test_malformed_multipart_boundary_syntax_is_a_client_error_without_mutation
    {
      'quoted boundary suffix' => ['multipart/form-data; boundary="Aa"junk', "--Aa--\r\n"],
      'missing empty-body boundary' => ['multipart/form-data', ''],
      'empty empty-body boundary' => ['multipart/form-data; boundary=', ''],
      'invalid empty-body boundary' => ['multipart/form-data; boundary=a@b', ''],
    }.each do |description, (content_type, body)|
      assert_equal @baseline, adapter_state, description
      response = raw_request(
        '/features/existing/boolean',
        method: 'POST',
        input: body,
        'CONTENT_TYPE' => content_type
      )

      assert_equal 400, response.first, description
      assert_equal @baseline, adapter_state, description
    end
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
