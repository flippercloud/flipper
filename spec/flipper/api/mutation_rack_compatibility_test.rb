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

  class PostEOFRangeErrorInput
    attr_reader :reads

    def initialize(contents)
      @contents = contents
      @reads = 0
    end

    def read(*)
      @reads += 1
      raise RangeError, 'post-EOF adapter failure' if @reads > 2
      return if @reads == 2

      @contents
    end

    def rewind
    end
  end

  class PostEOFEOFInput < PostEOFRangeErrorInput
    def read(*)
      @reads += 1
      raise EOFError, 'post-EOF adapter failure' if @reads > 2
      return if @reads == 2

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

  class ShortReadInput
    attr_reader :reads

    def initialize(*chunks)
      @chunks = chunks
      @index = 0
      @reads = 0
    end

    def read(length = nil)
      chunk = @chunks[@index]
      @index += 1
      @reads += 1
      raise 'test chunk exceeds requested length' if chunk && length && chunk.bytesize > length

      chunk
    end

    def rewind
      @index = 0
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

  class NonIdempotentCloseIO < StringIO
    attr_reader :close_calls

    def initialize
      super
      @close_calls = 0
    end

    def close
      @close_calls += 1
      raise 'closed twice' if @close_calls > 1

      super
    end
  end

  class NonIdempotentCloseIOWithoutClosed
    attr_reader :close_calls

    def initialize
      @io = StringIO.new
      @close_calls = 0
    end

    def <<(value)
      @io << value
      self
    end

    def rewind
      @io.rewind
    end

    def close
      @close_calls += 1
      raise 'closed twice' if @close_calls > 1

      @io.close
    end
  end

  class FirstCloseFailingMultipartIO < StringIO
    attr_reader :close_calls

    def initialize
      super
      @close_calls = 0
    end

    def close
      @close_calls += 1
      raise 'first close failed' if @close_calls == 1

      super
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

  def test_valid_quoted_pair_multipart_boundary_is_accepted
    boundary = 'A?a'
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"name\"\r\n\r\n" \
      "quoted_pair_boundary\r\n" \
      "--#{boundary}--\r\n"
    response = raw_request(
      '/features',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => 'multipart/form-data; boundary="A\\?a"'
    )

    assert_equal 200, response.first
    assert_includes @flipper.features.map(&:key), 'quoted_pair_boundary'
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

  def test_valid_import_remains_content_type_agnostic
    gates = {
      boolean: 'true',
      groups: [],
      actors: [],
      expression: nil,
      percentage_of_actors: nil,
      percentage_of_time: nil,
    }
    body = JSON.generate(features: {'percent%FF' => gates})

    [
      'application/json',
      'application/x-www-form-urlencoded',
      'multipart/form-data; boundary=Aa',
      'text/plain',
    ].each do |content_type|
      response = raw_request(
        '/import',
        method: 'POST',
        input: body,
        'CONTENT_TYPE' => content_type
      )

      assert_equal 204, response.first, content_type
      assert_equal ['percent%FF'], @flipper.features.map(&:key), content_type
    end
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

  def test_json_mutation_preserves_duplicate_query_scalar_semantics
    refute_includes @flipper.features.map(&:key), 'first'
    refute_includes @flipper.features.map(&:key), 'second'

    response = raw_request(
      '/features?name=first&name=second',
      method: 'POST',
      input: '{}',
      'CONTENT_TYPE' => 'application/json'
    )

    assert_equal 200, response.first
    refute_includes @flipper.features.map(&:key), 'first'
    assert_includes @flipper.features.map(&:key), 'second'
  end

  def test_json_middleware_preserves_nested_query_params
    captured_params = nil
    json_params = Flipper::Api::JsonParams.new(lambda do |env|
      captured_params = Rack::Request.new(env).params
      [200, {}, []]
    end)
    env = Rack::MockRequest.env_for(
      '/features?filter[name]=query',
      method: 'POST',
      input: '{}',
      'CONTENT_TYPE' => 'application/json'
    )

    status, = json_params.call(env)

    assert_equal 200, status
    assert_equal({'name' => 'query'}, captured_params['filter'])
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

  def test_boolean_expression_cannot_be_used_as_random_maximum
    [
      {Random: [{PercentageOfActors: ['User;1', 50]}]},
      {Random: [{All: [{Property: ['plan']}]}]},
      {Percentage: [{Boolean: [{Property: ['flag']}]}]},
      {Number: [{Boolean: [{Property: ['flag']}]}]},
      {Time: [{Boolean: [{Property: ['flag']}]}]},
    ].each do |expression|
      assert_equal @baseline, adapter_state, expression.inspect

      direct_response = raw_request(
        '/features/bad/expression',
        method: 'POST',
        input: JSON.generate(expression),
        'CONTENT_TYPE' => 'application/json'
      )

      assert_equal 422, direct_response.first, expression.inspect
      assert_equal @baseline, adapter_state, expression.inspect

      import_response = raw_request(
        '/import',
        method: 'POST',
        input: JSON.generate(features: {bad: {expression: expression}}),
        'CONTENT_TYPE' => 'application/json'
      )

      assert_equal 422, import_response.first, expression.inspect
      assert_equal @baseline, adapter_state, expression.inspect
    end
  end

  def test_nonnumeric_import_percentages_do_not_replace_state
    %w[percentage_of_actors percentage_of_time].product(['not-a-number', 'oops1']).each do |gate, value|
      body = JSON.generate(features: {replacement: {gate => value}})
      description = "#{gate}=#{value}"
      assert_equal @baseline, adapter_state, description

      response = raw_request(
        '/import',
        method: 'POST',
        input: body,
        'CONTENT_TYPE' => 'application/json'
      )

      assert_equal 422, response.first, description
      assert_equal @baseline, adapter_state, description
    end
  end

  def test_numeric_import_percentage_strings_remain_accepted
    values = {'0' => 0, '10' => 10, '10.5' => 10.5, '1e-7' => 1e-7,
              '1.0e-07' => 1e-7, '100e-2' => 1, '1e2' => 100, '100' => 100}
    %w[percentage_of_actors percentage_of_time].product(values.to_a).each do |gate, (value, expected)|
      body = JSON.generate(features: {replacement: {gate => value}})
      response = raw_request(
        '/import',
        method: 'POST',
        input: body,
        'CONTENT_TYPE' => 'application/json'
      )

      actual = if gate == 'percentage_of_actors'
        @flipper[:replacement].percentage_of_actors_value
      else
        @flipper[:replacement].percentage_of_time_value
      end
      description = "#{gate}=#{value}"
      assert_equal 204, response.first, description
      assert_equal expected, actual, description
    end
  end

  def test_tiny_percentage_round_trips_through_export_and_json_mutation
    source = Flipper.new(Flipper::Adapters::Memory.new)
    source[:tiny].enable_percentage_of_time(1e-7)

    import_response = raw_request(
      '/import',
      method: 'POST',
      input: source.export.contents,
      'CONTENT_TYPE' => 'application/json'
    )

    assert_equal 204, import_response.first
    assert_equal 1e-7, @flipper[:tiny].percentage_of_time_value

    direct_response = raw_request(
      '/features/direct_tiny/percentage_of_time',
      method: 'POST',
      input: JSON.generate(percentage: 1e-7),
      'CONTENT_TYPE' => 'application/json'
    )

    assert_equal 200, direct_response.first
    assert_equal 1e-7, @flipper[:direct_tiny].percentage_of_time_value
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

  def test_multipart_filename_can_contain_parameter_looking_text
    boundary = 'Aa'
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"name\"\r\n\r\n" \
      "quoted_filename\r\n" \
      "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"upload\"; filename=\"a; name=fake\"\r\n" \
      "Content-Type: text/plain\r\n\r\ncontents\r\n" \
      "--#{boundary}--\r\n"

    response = raw_request(
      '/features',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )

    assert_equal 200, response.first
    assert_includes @flipper.features.map(&:key), 'quoted_filename'
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

  def test_multipart_file_limit_does_not_close_application_io_twice
    boundary = 'Aa'
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"one\"; filename=\"one.txt\"\r\n" \
      "Content-Type: text/plain\r\n\r\none\r\n" \
      "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"two\"; filename=\"two.txt\"\r\n" \
      "Content-Type: text/plain\r\n\r\ntwo\r\n" \
      "--#{boundary}--\r\n"
    env = Rack::MockRequest.env_for(
      '/features/existing/boolean',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )
    tempfiles = []
    env['rack.multipart.tempfile_factory'] = lambda do |*, **|
      NonIdempotentCloseIO.new.tap { |tempfile| tempfiles << tempfile }
    end
    original_limit = Rack::Utils.multipart_file_limit
    Rack::Utils.multipart_file_limit = 1
    assert_equal @baseline, adapter_state

    status, = @app.call(env)

    assert_equal 400, status
    assert_equal [1], tempfiles.map(&:close_calls)
    assert_equal @baseline, adapter_state
  ensure
    Rack::Utils.multipart_file_limit = original_limit
    tempfiles.each { |tempfile| tempfile.close unless tempfile.closed? }
  end

  def test_multipart_file_limit_tracks_parser_close_without_closed_predicate
    boundary = 'Aa'
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"one\"; filename=\"one.txt\"\r\n" \
      "Content-Type: text/plain\r\n\r\none\r\n" \
      "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"two\"; filename=\"two.txt\"\r\n" \
      "Content-Type: text/plain\r\n\r\ntwo\r\n" \
      "--#{boundary}--\r\n"
    env = Rack::MockRequest.env_for(
      '/features/existing/boolean',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )
    tempfiles = []
    env['rack.multipart.tempfile_factory'] = lambda do |*, **|
      NonIdempotentCloseIOWithoutClosed.new.tap { |tempfile| tempfiles << tempfile }
    end
    original_limit = Rack::Utils.multipart_file_limit
    Rack::Utils.multipart_file_limit = 1
    assert_equal @baseline, adapter_state

    status, = @app.call(env)

    assert_equal 400, status
    assert_equal [1], tempfiles.map(&:close_calls)
    assert_equal @baseline, adapter_state
  ensure
    Rack::Utils.multipart_file_limit = original_limit
  end

  def test_multipart_file_limit_retries_a_failed_parser_close
    boundary = 'Aa'
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"one\"; filename=\"one.txt\"\r\n" \
      "Content-Type: text/plain\r\n\r\none\r\n" \
      "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"two\"; filename=\"two.txt\"\r\n" \
      "Content-Type: text/plain\r\n\r\ntwo\r\n" \
      "--#{boundary}--\r\n"
    env = Rack::MockRequest.env_for(
      '/features/existing/boolean',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )
    tempfiles = []
    env['rack.multipart.tempfile_factory'] = lambda do |*, **|
      FirstCloseFailingMultipartIO.new.tap { |tempfile| tempfiles << tempfile }
    end
    original_limit = Rack::Utils.multipart_file_limit
    Rack::Utils.multipart_file_limit = 1
    assert_equal @baseline, adapter_state

    error = assert_raises(RuntimeError) { @app.call(env) }

    assert_equal 'first close failed', error.message
    assert_equal [2], tempfiles.map(&:close_calls)
    assert tempfiles.all?(&:closed?)
    assert_equal @baseline, adapter_state
  ensure
    Rack::Utils.multipart_file_limit = original_limit
    tempfiles.each { |tempfile| tempfile.close unless tempfile.closed? }
  end

  def test_large_valid_json_params_do_not_reparse_through_rack_query_limits
    actor = Flipper::Actor.new('User;json-key-space')
    payload = {'flipper_id' => actor.flipper_id}
    10_000.times { |index| payload["ignored_#{index}"] = '' }
    body = JSON.generate(payload)
    assert_operator body.bytesize, :<, Flipper::Api::JsonParams::MAX_MUTATION_BODY_BYTES
    refute @flipper[:json_key_space].enabled?(actor)

    response = raw_request(
      '/features/json_key_space/actors',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => 'application/json'
    )

    assert_equal 200, response.first
    assert @flipper[:json_key_space].enabled?(actor)
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

  def test_rejected_multipart_tempfiles_close_without_an_outer_reaper
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
    assert_equal @baseline, adapter_state

    status, _, response_body = @app.call(env)

    assert_equal 400, status
    assert_equal 1, tempfiles.length
    assert tempfiles.first.closed?
    assert_empty env['rack.tempfiles']
    assert_equal @baseline, adapter_state
  ensure
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

  def test_short_reads_cannot_bypass_mutation_body_limit
    body = JSON.generate(name: 'short_read_mutation')
    input = ShortReadInput.new(body, 'x')
    env = Rack::MockRequest.env_for(
      '/features',
      method: 'POST',
      input: '',
      'CONTENT_TYPE' => 'application/json'
    )
    env['rack.input'] = input
    env['CONTENT_LENGTH'] = (body.bytesize + 1).to_s
    assert_equal @baseline, adapter_state

    with_replaced_constant(Flipper::Api::JsonParams, :MAX_MUTATION_BODY_BYTES, body.bytesize) do
      status, = Flipper::Api.app(@flipper, use_rewindable_middleware: false).call(env)
      assert_equal 400, status
    end

    assert_operator input.reads, :>, 1
    assert_equal @baseline, adapter_state
  end

  def test_short_reads_cannot_bypass_import_body_limit
    gates = {boolean: 'true', groups: [], actors: []}
    body = JSON.generate(features: {replacement: gates})
    input = ShortReadInput.new(body, 'x')
    env = Rack::MockRequest.env_for(
      '/import',
      method: 'POST',
      input: '',
      'CONTENT_TYPE' => 'application/json'
    )
    env['rack.input'] = input
    env['CONTENT_LENGTH'] = (body.bytesize + 1).to_s
    assert_equal @baseline, adapter_state

    with_replaced_constant(Flipper::Exporters::Json::Export, :MAX_BYTES, body.bytesize) do
      status, = Flipper::Api.app(@flipper, use_rewindable_middleware: false).call(env)
      assert_equal 422, status
    end

    assert_operator input.reads, :>, 1
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

  def test_validated_form_body_is_not_read_after_eof
    [PostEOFEOFInput, PostEOFRangeErrorInput].each do |input_class|
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
      assert_equal 2, input.reads, input_class.name
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

  def test_non_ascii_multipart_content_type_is_a_client_error_without_mutation
    assert_equal @baseline, adapter_state
    response = raw_request(
      '/features/existing/boolean',
      method: 'POST',
      input: "--Aa--\r\n",
      'CONTENT_TYPE' => "multipart/form-data; boundary=Aa; note=é"
    )

    assert_equal 400, response.first
    assert_equal @baseline, adapter_state
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

  def with_replaced_constant(owner, name, value)
    original = owner.const_get(name)
    owner.send(:remove_const, name)
    owner.const_set(name, value)
    yield
  ensure
    owner.send(:remove_const, name)
    owner.const_set(name, original)
  end

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
