RSpec.describe Flipper::Api::Action do
  let(:action_subclass) do
    Class.new(described_class) do
      def noooope
        raise 'should never run this'
      end

      def get
        [200, {}, 'get']
      end

      def head
        [200, {}, 'head']
      end

      def post
        [200, {}, 'post']
      end

      def put
        [200, {}, 'put']
      end

      def delete
        [200, {}, 'delete']
      end
    end
  end

  describe 'https verbs' do
    it "won't run method that isn't whitelisted" do
      fake_request = Struct.new(:request_method, :env, :session, :params).new('NOOOOPE', {}, {}, {})
      action = action_subclass.new(flipper, fake_request)
      expect do
        action.run
      end.to raise_error(Flipper::Api::RequestMethodNotSupported)
    end

    it 'will run get' do
      fake_request = Struct.new(:request_method, :env, :session, :params).new('GET', {}, {}, {})
      action = action_subclass.new(flipper, fake_request)
      expect(action.run).to eq([200, {}, 'get'])
    end

    it 'will run head' do
      fake_request = Struct.new(:request_method, :env, :session, :params).new('HEAD', {}, {}, {})
      action = action_subclass.new(flipper, fake_request)
      expect(action.run).to eq([200, {}, 'get'])
    end

    it 'will run post' do
      fake_request = Struct.new(:request_method, :env, :session, :params).new('POST', {}, {}, {})
      action = action_subclass.new(flipper, fake_request)
      expect(action.run).to eq([200, {}, 'post'])
    end

    it 'will run put' do
      fake_request = Struct.new(:request_method, :env, :session, :params).new('PUT', {}, {}, {})
      action = action_subclass.new(flipper, fake_request)
      expect(action.run).to eq([200, {}, 'put'])
    end

    it 'will run delete' do
      fake_request = Struct.new(:request_method, :env, :session, :params).new('DELETE', {}, {}, {})
      action = action_subclass.new(flipper, fake_request)
      expect(action.run).to eq([200, {}, 'delete'])
    end
  end

  describe '#json_error_response' do
    describe ':feature_not_found' do
      it 'locates and serializes error correctly' do
        action = action_subclass.new({}, {})
        response = catch(:halt) do
          action.json_error_response(:feature_not_found)
        end
        _, headers, body = response
        parsed_body = JSON.parse(body[0])

        expect(headers[Rack::CONTENT_TYPE]).to eq('application/json')
        expect(parsed_body).to eql(api_not_found_response)
      end
    end

    describe ':group_not_registered' do
      it 'locates and serializes error correctly' do
        action = action_subclass.new({}, {})
        response = catch(:halt) do
          action.json_error_response(:group_not_registered)
        end
        _, headers, body = response
        parsed_body = JSON.parse(body[0])

        expect(headers[Rack::CONTENT_TYPE]).to eq('application/json')
        expect(parsed_body['code']).to eq(2)
        expect(parsed_body['message']).to eq('Group not registered.')
        expect(parsed_body['more_info']).to eq(api_error_code_reference_url)
      end
    end

    describe 'invalid error key' do
      it 'raises descriptive error' do
        action = action_subclass.new({}, {})
        catch(:halt) do
          expect { action.json_error_response(:invalid_error_key) }.to raise_error(KeyError)
        end
      end
    end
  end

  describe 'safe parameters' do
    it 'does not classify unrelated application errors as parameter errors' do
      request = double('Request', request_method: 'GET')
      allow(request).to receive(:params).and_raise(ArgumentError, 'application failure')
      action = action_subclass.new(flipper, request)

      expect { action.send(:safe_params) }.to raise_error(ArgumentError, 'application failure')
    end

    it 'does not classify unrelated range errors on modern Rack as parameter errors' do
      request = double('Request', request_method: 'GET')
      allow(request).to receive(:params).and_raise(RangeError, 'application failure')
      action = action_subclass.new(flipper, request)

      expect { action.send(:safe_params) }.to raise_error(RangeError, 'application failure')
    end

    it 'does not classify action failures as client input errors' do
      request = double('Request', request_method: 'POST', params: {}, env: {})
      action = action_subclass.new(flipper, request)
      allow(action).to receive(:post).and_raise(ArgumentError, 'application failure')

      expect { action.run }.to raise_error(ArgumentError, 'application failure')
    end

    it 'classifies EOF from multipart parameter parsing as a client error' do
      request = double(
        'Request',
        request_method: 'POST',
        env: {'CONTENT_TYPE' => 'multipart/form-data; boundary=Aa'}
      )
      allow(request).to receive(:params).and_raise(EOFError, 'truncated multipart')
      action = action_subclass.new(flipper, request)

      status, = action.run

      expect(status).to eq(400)
    end

    it 'does not classify non-multipart EOF from parameter access as a client error' do
      request = double('Request', request_method: 'POST', env: {'CONTENT_TYPE' => 'application/x-www-form-urlencoded'})
      allow(request).to receive(:params).and_raise(EOFError, 'input failure')
      action = action_subclass.new(flipper, request)

      expect { action.run }.to raise_error(EOFError, 'input failure')
    end

    it 'does not classify action EOF failures as client input errors' do
      request = double('Request', request_method: 'POST', params: {}, env: {})
      action = action_subclass.new(flipper, request)
      allow(action).to receive(:post).and_raise(EOFError, 'application failure')

      expect { action.run }.to raise_error(EOFError, 'application failure')
    end

    Flipper::Api::ParameterParsing.errors.select { |error| error.name.to_s.include?('Multipart') }.each do |error|
      it "classifies #{error.name} as a client parameter error" do
        request = double('Request', request_method: 'POST', env: {})
        allow(request).to receive(:params).and_raise(error.new)
        action = action_subclass.new(flipper, request)

        status, = action.run

        expect(status).to eq(400)
      end
    end
  end
end
