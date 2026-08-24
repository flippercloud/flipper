require 'stringio'

RSpec.describe 'Flipper API mutation transport handling' do
  MUTATION_ENDPOINTS = [
    [:post, '/features'],
    [:delete, '/features/target'],
    [:post, '/features/target/boolean'],
    [:delete, '/features/target/boolean'],
    [:post, '/features/target/actors'],
    [:delete, '/features/target/actors'],
    [:post, '/features/target/groups'],
    [:delete, '/features/target/groups'],
    [:post, '/features/target/percentage_of_actors'],
    [:delete, '/features/target/percentage_of_actors'],
    [:post, '/features/target/percentage_of_time'],
    [:delete, '/features/target/percentage_of_time'],
    [:post, '/features/target/expression'],
    [:delete, '/features/target/expression'],
    [:delete, '/features/target/clear'],
    [:post, '/import'],
  ].freeze

  SCALAR_PARAMETERS = [
    ['/features', 'name'],
    ['/features/target/actors', 'flipper_id'],
    ['/features/target/groups', 'name'],
    ['/features/target/percentage_of_actors', 'percentage'],
    ['/features/target/percentage_of_time', 'percentage'],
  ].freeze

  let(:app) { build_api(flipper) }
  let(:actor) { Flipper::Actor.new('User;1') }

  before do
    Flipper.register(:admins) { false }
    flipper[:existing].enable
    flipper[:target].enable_actor(actor)
    flipper[:target].enable_group(:admins)
    flipper[:target].enable_percentage_of_actors(20)
    flipper[:target].enable_percentage_of_time(10)
    flipper[:target].enable_expression(Flipper.property(:plan).eq('basic'))
    baseline_state
  end

  MUTATION_ENDPOINTS.each do |method, path|
    it "rejects truncated JSON before #{method.to_s.upcase} #{path} mutates state" do
      invalid_mutation(method, path, '{"truncated":', 'application/json')
    end
  end

  {
    'null' => 'null',
    'array' => '[]',
    'string' => '"value"',
    'number' => '1',
    'boolean' => 'true',
  }.each do |description, body|
    it "rejects a JSON #{description} root before mutation" do
      invalid_mutation(:post, '/features', body, 'application/json', status: 400)
    end
  end

  SCALAR_PARAMETERS.each do |path, name|
    [:array, :hash].each do |shape|
      it "rejects a JSON #{shape} for scalar #{name.inspect} on #{path}" do
        value = shape == :array ? ['invalid'] : {nested: 'invalid'}
        invalid_mutation(:post, path, JSON.generate(name => value), 'application/json')
      end

      it "rejects a form #{shape} for scalar #{name.inspect} on #{path}" do
        body = shape == :array ? "#{name}[]=invalid" : "#{name}[nested]=invalid"
        invalid_mutation(:post, path, body, 'application/x-www-form-urlencoded')
      end
    end
  end

  [:array, :hash].each do |shape|
    it "rejects a JSON #{shape} for optional allow_unregistered_groups" do
      value = shape == :array ? ['true'] : {nested: 'true'}
      body = JSON.generate(name: 'unregistered', allow_unregistered_groups: value)
      invalid_mutation(:post, '/features/target/groups', body, 'application/json', status: 400)
    end
  end

  [
    'conflict=scalar&conflict[]=array',
    'conflict[]=array&conflict=scalar',
    'conflict=scalar&conflict[nested]=hash',
    'conflict[nested]=hash&conflict=scalar',
  ].each do |body|
    it "rejects conflicting form shapes in #{body.inspect}" do
      invalid_mutation(:post, '/features/target/boolean', body, 'application/x-www-form-urlencoded', status: 400)
    end

    it "rejects conflicting query shapes in #{body.inspect}" do
      invalid_mutation(
        :post,
        "/features/target/boolean?#{body}",
        '',
        'application/x-www-form-urlencoded',
        status: 400
      )
    end
  end

  [
    ['name[]=query', {'name' => 'created'}],
    ['name[nested]=query', {'name' => 'created'}],
    ['name=query', {'name' => ['created']}],
    ['name=query', {'name' => {'nested' => 'created'}}],
  ].each do |query, body|
    it "rejects query/JSON shape conflicts in #{query.inspect}" do
      invalid_mutation(
        :post,
        "/features?#{query}",
        JSON.generate(body),
        'application/json',
        status: 400
      )
    end
  end

  [
    ['name[]=query', 'name=body'],
    ['name[nested]=query', 'name=body'],
    ['name=query', 'name[]=body'],
    ['name=query', 'name[nested]=body'],
  ].each do |query, body|
    it "rejects query/form shape conflicts in #{query.inspect}" do
      invalid_mutation(
        :post,
        "/features?#{query}",
        body,
        'application/x-www-form-urlencoded',
        status: 400
      )
    end
  end

  it 'rejects invalid JSON encoding before mutation' do
    invalid_mutation(
      :post,
      '/features/target/boolean',
      ('{"ignored":"'.b + 255.chr + '"}'),
      'application/json',
      status: 400
    )
  end

  it 'rejects invalid form encoding before mutation' do
    invalid_mutation(
      :post,
      '/features/target/boolean',
      'ignored=%FF',
      'application/x-www-form-urlencoded',
      status: 400
    )
  end

  it 'rejects invalid query encoding before mutation' do
    invalid_mutation(
      :post,
      '/features/target/boolean?ignored=%FF',
      '{}',
      'application/json',
      status: 400
    )
  end

  it 'accepts application/json with a charset parameter' do
    post '/features',
         JSON.generate(name: 'json_charset'),
         'CONTENT_TYPE' => 'application/json; charset=utf-8'

    expect(last_response.status).to eq(200)
    expect(flipper.features.map(&:key)).to include('json_charset')
  end

  it 'preserves valid JSON and form scalar mutations' do
    post '/features', JSON.generate(name: 'valid_json'), 'CONTENT_TYPE' => 'application/json'
    expect(last_response.status).to eq(200)

    post '/features', 'name=valid_form', 'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
    expect(last_response.status).to eq(200)

    expect(flipper.features.map(&:key)).to include('valid_json', 'valid_form')
  end

  it 'continues to delegate valid multipart parsing to Rack' do
    boundary = 'flipper-boundary'
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"name\"\r\n\r\n" \
      "valid_multipart\r\n--#{boundary}--\r\n"

    post '/features', body, 'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"

    expect(last_response.status).to eq(200)
    expect(flipper.features.map(&:key)).to include('valid_multipart')
  end

  [
    [['conflict', 'scalar'], ['conflict[]', 'array']],
    [['conflict[]', 'array'], ['conflict', 'scalar']],
  ].each do |fields|
    it "rejects multipart shape conflicts in #{fields.inspect}" do
      boundary = 'flipper-boundary'
      parts = fields.map do |name, value|
        "--#{boundary}\r\n" \
          "Content-Disposition: form-data; name=\"#{name}\"\r\n\r\n" \
          "#{value}\r\n"
      end

      invalid_mutation(
        :post,
        '/features/target/boolean',
        "#{parts.join}--#{boundary}--\r\n",
        "multipart/form-data; boundary=#{boundary}",
        status: 400
      )
    end
  end

  it 'preserves Rack multipart semantics for heterogeneous array elements' do
    boundary = 'flipper-boundary'
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"ignored[]\"\r\n\r\n" \
      "scalar\r\n--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"ignored[][nested]\"\r\n\r\n" \
      "value\r\n--#{boundary}--\r\n"

    post '/features/target/boolean', body,
         'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"

    expect(last_response.status).to eq(200)
    expect(flipper[:target].boolean_value).to be(true)
  end

  it 'rejects excessively nested multipart fields without mutation' do
    boundary = 'flipper-boundary'
    name = "nested#{'[nested]' * 150}"
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"#{name}\"\r\n\r\n" \
      "value\r\n--#{boundary}--\r\n"

    invalid_mutation(
      :post,
      '/features/target/boolean',
      body,
      "multipart/form-data; boundary=#{boundary}",
      status: 400
    )
  end

  it 'accepts empty JSON bodies for bodyless mutations' do
    post '/features/target/boolean', '', 'CONTENT_TYPE' => 'application/json'

    expect(last_response.status).to eq(200)
    expect(flipper[:target].boolean_value).to be(true)
  end

  it 'rejects empty JSON bodies for required scalar mutations' do
    invalid_mutation(:post, '/features', '', 'application/json', status: 422)
  end

  it 'rejects unsupported compressed JSON before mutation' do
    invalid_mutation(
      :post,
      '/features',
      Flipper::Typecast.to_gzip(name: 'compressed'),
      'application/json',
      status: 400,
      headers: {'HTTP_CONTENT_ENCODING' => 'gzip'}
    )
  end

  it 'rejects oversized JSON before mutation without reading it unbounded' do
    stub_const('Flipper::Api::JsonParams::MAX_MUTATION_BODY_BYTES', 1)
    input = BoundedInput.new(JSON.generate(name: 'oversized'))
    env = Rack::MockRequest.env_for(
      '/features',
      method: 'POST',
      input: '',
      'CONTENT_TYPE' => 'application/json'
    )
    env['rack.input'] = input
    expect(adapter_state).to eq(baseline_state)

    status, = app.call(env)

    expect(status).to eq(400)
    expect(input.read_lengths).not_to include(nil)
    expect(adapter_state).to eq(baseline_state)
  end

  it 'rejects malformed import JSON before mutation' do
    invalid_mutation(:post, '/import', '{"features":', 'application/json', status: 422)
  end

  [nil, [], 'invalid', 1, true].each do |root|
    it "rejects import root #{root.inspect} before mutation" do
      invalid_mutation(:post, '/import', JSON.generate(root), 'application/json', status: 422)
    end
  end

  it 'rejects oversized imports using the bounded reader' do
    stub_const('Flipper::Exporters::Json::Export::MAX_BYTES', 1)
    input = BoundedInput.new(JSON.generate(features: {}))
    env = Rack::MockRequest.env_for(
      '/import',
      method: 'POST',
      input: '',
      'CONTENT_TYPE' => 'application/json'
    )
    env['rack.input'] = input
    expect(adapter_state).to eq(baseline_state)

    status, = app.call(env)

    expect(status).to eq(422)
    expect(input.read_lengths).not_to include(nil)
    expect(adapter_state).to eq(baseline_state)
  end

  it 'does not classify JSON parser errors from rack.input as client errors' do
    input = double('Input', rewind: nil)
    allow(input).to receive(:read).and_raise(JSON::ParserError, 'input failure')
    env = Rack::MockRequest.env_for(
      '/features',
      method: 'POST',
      input: '',
      'CONTENT_TYPE' => 'application/json'
    )
    env['rack.input'] = input

    expect { app.call(env) }.to raise_error(JSON::ParserError, 'input failure')
    expect(adapter_state).to eq(baseline_state)
  end

  it 'does not classify form input stream range errors as client errors' do
    env = Rack::MockRequest.env_for(
      '/features',
      method: 'POST',
      input: '',
      'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
    )
    env['rack.input'] = RangeErrorInput.new
    unrewound_app = Flipper::Api.app(flipper, use_rewindable_middleware: false)

    expect { unrewound_app.call(env) }.to raise_error(RangeError, 'input failure')
    expect(adapter_state).to eq(baseline_state)
  end

  it 'does not classify adapter JSON parser errors as invalid imports' do
    allow(flipper).to receive(:import).and_raise(JSON::ParserError, 'adapter failure')
    body = build_flipper.export.contents
    expect(adapter_state).to eq(baseline_state)

    expect do
      post '/import', body, 'CONTENT_TYPE' => 'application/json'
    end.to raise_error(JSON::ParserError, 'adapter failure')

    expect(adapter_state).to eq(baseline_state)
  end

  it 'does not classify adapter argument errors as invalid client input' do
    allow(flipper.adapter).to receive(:add).and_raise(ArgumentError, 'adapter failure')

    expect do
      post '/features', JSON.generate(name: 'unreachable'), 'CONTENT_TYPE' => 'application/json'
    end.to raise_error(ArgumentError, 'adapter failure')

    expect(adapter_state).to eq(baseline_state)
  end

  it 'does not classify multipart tempfile factory errors as invalid client input' do
    boundary = 'flipper-boundary'
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
    env['rack.multipart.tempfile_factory'] = lambda do |*|
      raise ArgumentError, 'tempfile failure'
    end

    expect { app.call(env) }.to raise_error(ArgumentError, 'tempfile failure')
    expect(adapter_state).to eq(baseline_state)
  end

  it 'does not classify named Rack parser errors from a multipart callback as client input' do
    boundary = 'flipper-boundary'
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
    error_class = Flipper::Api::ParameterParsing.errors.find do |error|
      error.name.end_with?('ParameterTypeError')
    end
    env['rack.multipart.tempfile_factory'] = lambda do |*|
      raise error_class, 'factory failure'
    end

    expect { app.call(env) }.to raise_error(error_class, 'factory failure')
    expect(adapter_state).to eq(baseline_state)
  end

  it 'does not invoke the application multipart tempfile factory during shape validation' do
    boundary = 'flipper-boundary'
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"name\"\r\n\r\n" \
      "factory_once\r\n" \
      "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"upload\"; filename=\"file.txt\"\r\n" \
      "Content-Type: text/plain\r\n\r\ncontents\r\n" \
      "--#{boundary}--\r\n"
    env = Rack::MockRequest.env_for(
      '/features',
      method: 'POST',
      input: body,
      'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"
    )
    calls = 0
    env['rack.multipart.tempfile_factory'] = lambda do |*|
      calls += 1
      StringIO.new
    end

    status, = app.call(env)

    expect(status).to eq(200)
    expect(calls).to eq(1)
    expect(flipper.features.map(&:key)).to include('factory_once')
  end

  class BoundedInput < StringIO
    attr_reader :read_lengths

    def initialize(contents)
      super
      @read_lengths = []
    end

    def read(length = nil, buffer = nil)
      @read_lengths << length
      super
    end
  end

  class RangeErrorInput
    def read(*)
      raise RangeError, 'input failure'
    end

    def rewind
    end
  end

  def invalid_mutation(method, path, body, content_type, status: nil, headers: {})
    expect(adapter_state).to eq(baseline_state)

    public_send(
      method,
      path,
      body,
      {'CONTENT_TYPE' => content_type}.merge(headers)
    )

    if status
      expect(last_response.status).to eq(status)
    else
      expect([400, 422]).to include(last_response.status)
    end
    expect(adapter_state).to eq(baseline_state)
  end

  def baseline_state
    @baseline_state ||= adapter_state
  end

  def adapter_state
    Marshal.load(Marshal.dump(flipper.adapter.get_all))
  end
end
