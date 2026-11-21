RSpec.describe Flipper::Api::JsonParams do
  let(:app) do
    app = lambda do |env|
      request = Rack::Request.new(env)
      [200, { 'Content-Type' => 'application/json' }, [JSON.generate(request.params)]]
    end
    builder = Rack::Builder.new
    builder.use described_class
    builder.run app
    builder
  end

  describe 'json post request' do
    it 'adds request body to params' do
      response = post '/',
                      JSON.generate(flipper_id: 'User;2'),
                      'CONTENT_TYPE' => 'application/json'

      params = JSON.parse(response.body)
      expect(params).to eq('flipper_id' => 'User;2')
    end

    it 'handles request bodies with multiple params' do
      response = post '/',
                      JSON.generate(flipper_id: 'User;2', language: 'ruby'),
                      'CONTENT_TYPE' => 'application/json'

      params = JSON.parse(response.body)
      expect(params).to eq('flipper_id' => 'User;2', 'language' => 'ruby')
    end

    it 'handles request bodies and single query string params' do
      response = post '/?language=ruby',
                      JSON.generate(flipper_id: 'User;2'),
                      'CONTENT_TYPE' => 'application/json'

      params = JSON.parse(response.body)
      expect(params).to eq('flipper_id' => 'User;2', 'language' => 'ruby')
    end

    it 'handles request bodies and multiple query string params' do
      response = post '/?language=ruby&framework=rails',
                      JSON.generate(flipper_id: 'User;2'),
                      'CONTENT_TYPE' => 'application/json'

      params = JSON.parse(response.body)
      expect(params).to eq('flipper_id' => 'User;2', 'language' => 'ruby', 'framework' => 'rails')
    end

    it 'favors request body params' do
      response = post '/?language=javascript',
                      JSON.generate(flipper_id: 'User;2', language: 'ruby'),
                      'CONTENT_TYPE' => 'application/json'

      params = JSON.parse(response.body)
      expect(params).to eq('flipper_id' => 'User;2', 'language' => 'ruby')
    end
  end

  describe 'json get request with a body it cannot use' do
    {
      'malformed JSON' => '{bad',
      'null' => 'null',
      'an array' => '[1, 2]',
      'a string' => '"ruby"',
      'invalid UTF-8' => "\xFF\xFE".b,
    }.each do |description, body|
      it "ignores a body of #{description}" do
        status, _headers, response_body = call_app(
          Rack::MockRequest.env_for('/?language=ruby', method: 'GET', input: body, 'CONTENT_TYPE' => 'application/json')
        )

        expect(status).to eq(200)
        expect(JSON.parse(response_body)).to eq('language' => 'ruby')
      end
    end

    it 'still rejects malformed JSON on a post' do
      status, = call_app(
        Rack::MockRequest.env_for('/', method: 'POST', input: '{bad', 'CONTENT_TYPE' => 'application/json')
      )

      expect(status).to eq(400)
    end
  end

  describe 'json request without rack.input' do
    it 'handles a get like an empty body' do
      status, _headers, body = call_without_rack_input('/?language=ruby', 'CONTENT_TYPE' => 'application/json')

      expect(status).to eq(200)
      expect(JSON.parse(body)).to eq('language' => 'ruby')
    end

    it 'handles a post like an empty body' do
      status, _headers, body = call_without_rack_input('/?language=ruby', method: 'POST', 'CONTENT_TYPE' => 'application/json')

      expect(status).to eq(200)
      expect(JSON.parse(body)).to eq('language' => 'ruby')
    end
  end

  describe 'url-encoded request' do
    it 'handles params the same as a json request' do
      response = post '/', flipper_id: 'User;2'
      params = JSON.parse(response.body)
      expect(params).to eq('flipper_id' => 'User;2')
    end

    it 'handles single query string params' do
      response = post '/?language=ruby', flipper_id: 'User;2'
      params = JSON.parse(response.body)
      expect(params).to eq('flipper_id' => 'User;2', 'language' => 'ruby')
    end

    it 'handles multiple query string params' do
      response = post '/?language=ruby&framework=rails', flipper_id: 'User;2'
      params = JSON.parse(response.body)
      expect(params).to eq('flipper_id' => 'User;2', 'language' => 'ruby', 'framework' => 'rails')
    end
  end
end
