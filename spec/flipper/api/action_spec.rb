RSpec.describe Flipper::Api::Action do
  let(:action_subclass) do
    Class.new(described_class) do
      def noooope
        raise 'should never run this'
      end

      def get
        [200, {}, 'get']
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
      fake_request = Struct.new(:request_method, :env, :session).new('NOOOOPE', {}, {})
      action = action_subclass.new(flipper, fake_request)
      expect do
        action.run
      end.to raise_error(Flipper::Api::RequestMethodNotSupported)
    end

    it 'will run get' do
      fake_request = Struct.new(:request_method, :env, :session).new('GET', {}, {})
      action = action_subclass.new(flipper, fake_request)
      expect(action.run).to eq([200, {}, 'get'])
    end

    it 'will run post' do
      fake_request = Struct.new(:request_method, :env, :session).new('POST', {}, {})
      action = action_subclass.new(flipper, fake_request)
      expect(action.run).to eq([200, {}, 'post'])
    end

    it 'will run put' do
      fake_request = Struct.new(:request_method, :env, :session).new('PUT', {}, {})
      action = action_subclass.new(flipper, fake_request)
      expect(action.run).to eq([200, {}, 'put'])
    end

    it 'will run delete' do
      fake_request = Struct.new(:request_method, :env, :session).new('DELETE', {}, {})
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
        status, headers, body = response
        parsed_body = JSON.parse(body[0])

        expect(headers['Content-Type']).to eq('application/json')
        expect(parsed_body).to eql(api_not_found_response)
      end
    end

    describe ':group_not_registered' do
      it 'locates and serializes error correctly' do
        action = action_subclass.new({}, {})
        response = catch(:halt) do
          action.json_error_response(:group_not_registered)
        end
        status, headers, body = response
        parsed_body = JSON.parse(body[0])

        expect(headers['Content-Type']).to eq('application/json')
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
end
