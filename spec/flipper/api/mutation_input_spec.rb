require 'stringio'

RSpec.describe 'Flipper API mutation input handling' do
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

  JSON_ROOTS = {
    'null' => 'null',
    'array' => '[]',
    'string' => '"value"',
    'number' => '1',
    'boolean' => 'true',
  }.freeze

  SCALAR_PARAMETER_SHAPES = [
    ['/features', 'name'],
    ['/features/target/actors', 'flipper_id'],
    ['/features/target/groups', 'name'],
    ['/features/target/percentage_of_actors', 'percentage'],
    ['/features/target/percentage_of_time', 'percentage'],
  ].freeze

  REQUIRED_BODY_ENDPOINTS = [
    [:post, '/features'],
    [:post, '/features/target/actors'],
    [:post, '/features/target/groups'],
    [:post, '/features/target/percentage_of_actors'],
    [:post, '/features/target/percentage_of_time'],
    [:post, '/features/target/expression'],
    [:post, '/import'],
  ].freeze

  CONFLICTING_FORM_SHAPES = [
    'conflict=scalar&conflict[]=array',
    'conflict[]=array&conflict=scalar',
    'conflict=scalar&conflict[nested]=hash',
    'conflict[nested]=hash&conflict=scalar',
  ].freeze

  INVALID_FEATURE_NAME_MUTATIONS = [
    [:delete, '/features/%FF', '', 'application/json'],
    [:post, '/features/%FF/boolean', '', 'application/json'],
    [:delete, '/features/%FF/boolean', '', 'application/json'],
    [:post, '/features/%FF/actors', 'flipper_id=User%3B2', 'application/x-www-form-urlencoded'],
    [:delete, '/features/%FF/actors', 'flipper_id=User%3B1', 'application/x-www-form-urlencoded'],
    [:post, '/features/%FF/groups', 'name=admins', 'application/x-www-form-urlencoded'],
    [:delete, '/features/%FF/groups', 'name=admins', 'application/x-www-form-urlencoded'],
    [:post, '/features/%FF/percentage_of_actors', 'percentage=10', 'application/x-www-form-urlencoded'],
    [:delete, '/features/%FF/percentage_of_actors', '', 'application/json'],
    [:post, '/features/%FF/percentage_of_time', 'percentage=10', 'application/x-www-form-urlencoded'],
    [:delete, '/features/%FF/percentage_of_time', '', 'application/json'],
    [:post, '/features/%FF/expression', '{"Equal":["a","b"]}', 'application/json'],
    [:delete, '/features/%FF/expression', '', 'application/json'],
    [:delete, '/features/%FF/clear', '', 'application/json'],
  ].freeze

  let(:app) { build_api(flipper) }
  let(:actor) { Flipper::Actor.new('User;1') }
  let(:expression) { Flipper.property(:plan).eq('basic') }

  before do
    Flipper.register(:admins) { false }
    flipper[:existing].enable
    flipper[:target].enable_actor(actor)
    flipper[:target].enable_group(:admins)
    flipper[:target].enable_percentage_of_actors(20)
    flipper[:target].enable_percentage_of_time(10)
    flipper[:target].enable_expression(expression)
    baseline_state
  end

  MUTATION_ENDPOINTS.each do |method, path|
    it "rejects malformed JSON before #{method.to_s.upcase} #{path} mutates state" do
      expect(adapter_state).to eq(baseline_state)

      public_send(method, path, '{"truncated":', 'CONTENT_TYPE' => 'application/json')

      expect([400, 422]).to include(last_response.status)
      expect(adapter_state).to eq(baseline_state)
    end
  end

  it 'rejects malformed JSON syntax before mutation' do
    expect(adapter_state).to eq(baseline_state)

    post '/features/target/boolean', '{"invalid":]}', 'CONTENT_TYPE' => 'application/json'

    expect(last_response.status).to eq(400)
    expect(adapter_state).to eq(baseline_state)
  end

  MUTATION_ENDPOINTS.each do |method, path|
    CONFLICTING_FORM_SHAPES.each do |body|
      it "rejects conflicting form shapes in #{body.inspect} before #{method.to_s.upcase} #{path} mutates state" do
        expect(adapter_state).to eq(baseline_state)

        public_send(
          method,
          path,
          body,
          'CONTENT_TYPE' => 'application/x-www-form-urlencoded'
        )

        expect([400, 422]).to include(last_response.status)
        expect(adapter_state).to eq(baseline_state)
      end
    end
  end

  JSON_ROOTS.each do |description, body|
    it "rejects a JSON #{description} root before mutation" do
      expect(adapter_state).to eq(baseline_state)

      post '/features/target/boolean', body, 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(400)
      expect(adapter_state).to eq(baseline_state)
    end
  end

  INVALID_FEATURE_NAME_MUTATIONS.each do |method, path, body, content_type|
    it "rejects invalid route encoding before #{method.to_s.upcase} #{path} mutates state" do
      expect(adapter_state).to eq(baseline_state)

      public_send(method, path, body, 'CONTENT_TYPE' => content_type)

      expect(last_response.status).to eq(400)
      expect(adapter_state).to eq(baseline_state)
    end
  end

  SCALAR_PARAMETER_SHAPES.each do |path, parameter|
    [:array, :hash].each do |shape|
      it "rejects a form #{shape} for scalar #{parameter} on #{path} before mutation" do
        scalar = parameter == 'percentage' ? '10' : 'invalid'
        value = shape == :array ? "#{parameter}[]=#{scalar}" : "#{parameter}[nested]=#{scalar}"
        expect(adapter_state).to eq(baseline_state)

        post path, value, 'CONTENT_TYPE' => 'application/x-www-form-urlencoded'

        expect([400, 422]).to include(last_response.status)
        expect(adapter_state).to eq(baseline_state)
      end
    end
  end

  [:array, :hash].each do |shape|
    it "rejects a JSON #{shape} for a scalar feature name before mutation" do
      value = shape == :array ? ['invalid'] : {nested: 'invalid'}
      expect(adapter_state).to eq(baseline_state)

      post '/features', JSON.generate(name: value), 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(422)
      expect(adapter_state).to eq(baseline_state)
    end
  end

  [:array, :hash].each do |shape|
    it "rejects a form #{shape} for the optional allow_unregistered_groups scalar before mutation" do
      value = shape == :array ? 'allow_unregistered_groups[]=true' : 'allow_unregistered_groups[nested]=true'
      expect(adapter_state).to eq(baseline_state)

      post '/features/target/groups',
           "name=unregistered&#{value}",
           'CONTENT_TYPE' => 'application/x-www-form-urlencoded'

      expect(last_response.status).to eq(400)
      expect(adapter_state).to eq(baseline_state)
    end

    it "rejects a JSON #{shape} for the optional allow_unregistered_groups scalar before mutation" do
      value = shape == :array ? ['true'] : {nested: 'true'}
      expect(adapter_state).to eq(baseline_state)

      post '/features/target/groups',
           JSON.generate(name: 'unregistered', allow_unregistered_groups: value),
           'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(400)
      expect(adapter_state).to eq(baseline_state)
    end
  end

  it 'rejects conflicting form parameter shapes before mutation' do
    expect(adapter_state).to eq(baseline_state)

    post '/features',
         'name=first&name[]=second',
         'CONTENT_TYPE' => 'application/x-www-form-urlencoded'

    expect(last_response.status).to eq(400)
    expect(adapter_state).to eq(baseline_state)
  end

  [
    'conflict=scalar&conflict[]=array',
    'conflict[]=array&conflict=scalar',
    'conflict=scalar&conflict[nested]=hash',
    'conflict[nested]=hash&conflict=scalar',
  ].each do |query|
    it "rejects conflicting query parameter shapes in #{query.inspect} before mutation" do
      expect(adapter_state).to eq(baseline_state)

      post "/features/target/boolean?#{query}",
           '',
           'CONTENT_TYPE' => 'application/x-www-form-urlencoded'

      expect(last_response.status).to eq(400)
      expect(adapter_state).to eq(baseline_state)
    end
  end

  [
    ['name[]=query', 'name=body'],
    ['name[nested]=query', 'name=body'],
    ['name=query', 'name[]=body'],
    ['name=query', 'name[nested]=body'],
  ].each do |query, body|
    it "rejects cross-source form conflicts in #{query.inspect} and #{body.inspect} before mutation" do
      expect(adapter_state).to eq(baseline_state)

      post "/features?#{query}",
           body,
           'CONTENT_TYPE' => 'application/x-www-form-urlencoded'

      expect(last_response.status).to eq(400)
      expect(adapter_state).to eq(baseline_state)
    end
  end

  it 'rejects semicolon-separated conflicting form shapes on Rack 2 before mutation' do
    skip 'Rack 3 treats semicolons as form data, not separators' if Gem::Version.new(Rack.release) >= Gem::Version.new('3.0.0')
    expect(adapter_state).to eq(baseline_state)

    post '/features/target/boolean',
         'conflict[]=array;conflict=scalar',
         'CONTENT_TYPE' => 'application/x-www-form-urlencoded'

    expect(last_response.status).to eq(400)
    expect(adapter_state).to eq(baseline_state)
  end

  [
    [['name[]', 'array', true], ['name', 'scalar', true]],
    [['name[]', 'array', true], ['name', 'scalar', false]],
  ].each do |fields|
    it "rejects conflicting multipart parameter shapes in #{fields.inspect} before mutation" do
      boundary = 'flipper-boundary'
      body = multipart_body(boundary, fields)
      expect(adapter_state).to eq(baseline_state)

      post '/features',
           body,
           'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"

      expect(last_response.status).to eq(400)
      expect(adapter_state).to eq(baseline_state)
    end
  end

  it 'rejects duplicate multipart name parameters before mutation' do
    boundary = 'Aa'
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"name[]\"; name=\"name\"\r\n\r\n" \
      "scalar\r\n--#{boundary}--\r\n"
    expect(adapter_state).to eq(baseline_state)

    post '/features?name[]=query',
         body,
         'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"

    expect(last_response.status).to eq(400)
    expect(adapter_state).to eq(baseline_state)
  end

  it 'rejects ambiguous multipart quoted-pair names before mutation' do
    boundary = 'Aa'
    body = "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"na\\me\"\r\n\r\n" \
      "scalar\r\n--#{boundary}--\r\n"
    expect(adapter_state).to eq(baseline_state)

    post '/features?name[]=query',
         body,
         'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"

    expect(last_response.status).to eq(400)
    expect(adapter_state).to eq(baseline_state)
  end

  [
    ['name[]=query', 'name'],
    ['name[nested]=query', 'name'],
    ['name=query', 'name[]'],
    ['name=query', 'name[nested]'],
  ].each do |query, multipart_name|
    it "rejects cross-source multipart conflicts in #{query.inspect} and #{multipart_name.inspect} before mutation" do
      boundary = 'flipper-boundary'
      body = multipart_body(boundary, [[multipart_name, 'body', true]])
      expect(adapter_state).to eq(baseline_state)

      post "/features?#{query}",
           body,
           'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"

      expect(last_response.status).to eq(400)
      expect(adapter_state).to eq(baseline_state)
    end
  end

  [
    ['multipart/form-data', 'garbage'],
    ['multipart/form-data; boundary=', 'garbage'],
    ['multipart/form-data; boundary=Aa', "--Aa\r\nContent-Disposition: form-data; name=\"ignored\"\r\n\r\ntruncated"],
    ['multipart/form-data; boundary=Aa', "--Aa\r\nX-Test: bad\r\n\r\njunk\r\n--Aa--\r\n"],
    ['multipart/form-data; boundary=Aa', "bad-opening\r\n--Aa--\r\n"],
    ['multipart/form-data; boundary=Aa', "--Aa\r\nContent-Disposition: form-data; name=\"ignored\"\r\n\r\nvalue--Aa--\r\n"],
    ['multipart/form-data; boundary=Aa', "--Aa\r\nContent-Disposition: form-data; filename=\"ignored\"\r\n\r\nvalue\r\n--Aa--\r\n"],
    ['multipart/form-data; boundary=Aa', "--Aa\r\nContent-Disposition: form-data; name=\"\xFF\"\r\n\r\nvalue\r\n--Aa--\r\n".b],
  ].each do |content_type, body|
    it "rejects malformed multipart input with #{content_type.inspect} before mutation" do
      expect(adapter_state).to eq(baseline_state)

      post '/features/target/boolean', body, 'CONTENT_TYPE' => content_type

      expect(last_response.status).to eq(400)
      expect(adapter_state).to eq(baseline_state)
    end
  end

  it 'rejects malformed form encoding before mutation' do
    expect(adapter_state).to eq(baseline_state)

    post '/features', 'name=%FF', 'CONTENT_TYPE' => 'application/x-www-form-urlencoded'

    expect([400, 422]).to include(last_response.status)
    expect(adapter_state).to eq(baseline_state)
  end

  it 'rejects malformed JSON encoding before mutation' do
    body = "{\"name\":\"\xFF\"}".b
    expect(adapter_state).to eq(baseline_state)

    post '/features', body, 'CONTENT_TYPE' => 'application/json'

    expect([400, 422]).to include(last_response.status)
    expect(adapter_state).to eq(baseline_state)
  end

  it 'rejects invalid JSON encoding in an ignored parameter before mutation' do
    body = "{\"ignored\":\"\xFF\"}".b
    expect(adapter_state).to eq(baseline_state)

    post '/features/target/boolean', body, 'CONTENT_TYPE' => 'application/json'

    expect(last_response.status).to eq(400)
    expect(adapter_state).to eq(baseline_state)
  end

  it 'rejects invalid form encoding in an ignored parameter before mutation' do
    expect(adapter_state).to eq(baseline_state)

    post '/features/target/boolean',
         'ignored=%FF',
         'CONTENT_TYPE' => 'application/x-www-form-urlencoded'

    expect(last_response.status).to eq(400)
    expect(adapter_state).to eq(baseline_state)
  end

  it 'rejects invalid query encoding before a JSON mutation' do
    expect(adapter_state).to eq(baseline_state)

    post '/features/target/boolean?ignored=%FF',
         '{}',
         'CONTENT_TYPE' => 'application/json'

    expect(last_response.status).to eq(400)
    expect(adapter_state).to eq(baseline_state)
  end

  REQUIRED_BODY_ENDPOINTS.each do |method, path|
    it "rejects an empty body for #{method.to_s.upcase} #{path} without mutating state" do
      expect(adapter_state).to eq(baseline_state)

      public_send(method, path, '', 'CONTENT_TYPE' => 'application/json')

      expect(last_response.status).to eq(422)
      expect(adapter_state).to eq(baseline_state)
    end
  end

  it 'accepts a JSON object with a charset parameter' do
    post '/features',
         JSON.generate(name: 'json_charset'),
         'CONTENT_TYPE' => 'application/json; charset=utf-8'

    expect(last_response.status).to eq(200)
    expect(flipper.features.map(&:key)).to include('json_charset')
  end

  it 'accepts valid JSON actor and group mutations' do
    post '/features/target/actors',
         JSON.generate(flipper_id: 'User;2'),
         'CONTENT_TYPE' => 'application/json'
    post '/features/target/groups',
         JSON.generate(name: 'admins'),
         'CONTENT_TYPE' => 'application/json'

    expect(last_response.status).to eq(200)
    expect(flipper[:target].actors_value).to include('User;2')
    expect(flipper[:target].groups_value).to include('admins')
  end

  it 'accepts identity content encoding for a valid JSON mutation' do
    post '/features',
         JSON.generate(name: 'identity_encoding'),
         'CONTENT_TYPE' => 'application/json',
         'HTTP_CONTENT_ENCODING' => 'identity'

    expect(last_response.status).to eq(200)
    expect(flipper.features.map(&:key)).to include('identity_encoding')
  end

  [
    [:post, '/features/target/boolean'],
    [:delete, '/features/target/boolean'],
    [:delete, '/features/target/clear'],
  ].each do |method, path|
    it "accepts an empty JSON body for bodyless #{method.to_s.upcase} #{path}" do
      public_send(method, path, '', 'CONTENT_TYPE' => 'application/json')

      expect([200, 204]).to include(last_response.status)
    end
  end

  it 'continues to accept valid form scalar parameters' do
    post '/features', 'name=valid_form', 'CONTENT_TYPE' => 'application/x-www-form-urlencoded'

    expect(last_response.status).to eq(200)
    expect(flipper.features.map(&:key)).to include('valid_form')
  end

  ['valid_multipart', 'value--flipper-boundaryinside'].each do |value|
    it "continues to accept multipart scalar #{value.inspect}" do
      boundary = 'flipper-boundary'
      body = multipart_body(boundary, [['name', value, true]])

      post '/features',
           body,
           'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"

      expect(last_response.status).to eq(200)
      expect(flipper.features.map(&:key)).to include(value)
    end
  end

  it 'accepts an empty multipart body for a bodyless mutation' do
    boundary = 'flipper-boundary'

    post '/features/target/boolean',
         "--#{boundary}--\r\n",
         'CONTENT_TYPE' => "multipart/form-data; boundary=#{boundary}"

    expect(last_response.status).to eq(200)
  end

  it 'rejects an oversized JSON mutation body before mutation' do
    stub_const('Flipper::Api::JsonParams::MAX_MUTATION_BODY_BYTES', 1)
    expect(adapter_state).to eq(baseline_state)

    post '/features', JSON.generate(name: 'oversized'), 'CONTENT_TYPE' => 'application/json'

    expect(last_response.status).to eq(400)
    expect(adapter_state).to eq(baseline_state)
  end

  it 'rejects an oversized form mutation body before mutation' do
    stub_const('Flipper::Api::JsonParams::MAX_MUTATION_BODY_BYTES', 1)
    expect(adapter_state).to eq(baseline_state)

    post '/features', 'name=oversized', 'CONTENT_TYPE' => 'application/x-www-form-urlencoded'

    expect(last_response.status).to eq(400)
    expect(adapter_state).to eq(baseline_state)
  end

  it 'rejects unsupported compressed mutation bodies before mutation' do
    compressed_body = Flipper::Typecast.to_gzip(name: 'compressed')
    expect(adapter_state).to eq(baseline_state)

    post '/features',
         compressed_body,
         'CONTENT_TYPE' => 'application/json',
         'HTTP_CONTENT_ENCODING' => 'gzip'

    expect(last_response.status).to eq(400)
    expect(adapter_state).to eq(baseline_state)
  end

  it 'leaves import body-size enforcement at the bounded import reader' do
    stub_const('Flipper::Exporters::Json::Export::MAX_BYTES', 1)
    input = BoundedInput.new(JSON.generate(features: {}))
    env = Rack::MockRequest.env_for(
      '/import',
      method: 'POST',
      'CONTENT_TYPE' => 'application/json',
      input: input
    )
    env['rack.input'] = input
    expect(adapter_state).to eq(baseline_state)

    status, = app.call(env)

    expect(status).to eq(422)
    expect(input.read_lengths).not_to include(nil)
    expect(adapter_state).to eq(baseline_state)
  end

  {
    'root null' => nil,
    'root array' => [],
    'root string' => 'invalid',
    'root number' => 1,
    'root boolean' => true,
    'features as an array' => {features: []},
    'feature gates as an array' => {features: {bad: []}},
    'groups as a string' => {features: {bad: {groups: 'not-an-array'}}},
    'groups with a non-string member' => {features: {bad: {groups: [1]}}},
    'actors as a hash' => {features: {bad: {actors: {id: 'User;2'}}}},
    'actors with a non-string member' => {features: {bad: {actors: [1]}}},
    'boolean as a container' => {features: {bad: {boolean: []}}},
    'percentage as a container' => {features: {bad: {percentage_of_time: []}}},
    'expression as an array' => {features: {bad: {expression: []}}},
    'unknown expression operator' => {features: {bad: {expression: {Unknown: []}}}},
    'unknown gate' => {features: {bad: {unknown: 'value'}}},
  }.each do |description, payload|
    it "rejects import #{description} before replacing adapter state" do
      expect(adapter_state).to eq(baseline_state)

      post '/import', JSON.generate(payload), 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(422)
      expect(adapter_state).to eq(baseline_state)
    end
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

  def baseline_state
    @baseline_state ||= adapter_state
  end

  def adapter_state
    Marshal.load(Marshal.dump(flipper.adapter.get_all))
  end

  def multipart_body(boundary, fields)
    parts = fields.map do |name, value, quoted|
      encoded_name = quoted == false ? name : "\"#{name}\""
      "--#{boundary}\r\n" \
        "Content-Disposition: form-data; name=#{encoded_name}\r\n\r\n" \
        "#{value}\r\n"
    end
    "#{parts.join}--#{boundary}--\r\n"
  end
end
