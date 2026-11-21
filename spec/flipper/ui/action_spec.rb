RSpec.describe Flipper::UI::Action do
  describe 'request methods' do
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

    it "answers 405 for a method that isn't whitelisted" do
      fake_request = Struct.new(:request_method, :env, :session).new('NOOOOPE', {}, {})
      action = action_subclass.new(flipper, fake_request)
      status, headers, body = action.run
      expect(status).to eq(405)
      expect(headers['allow']).to eq('HEAD, GET, POST, PUT, DELETE')
      expect(headers[Rack::CONTENT_TYPE]).to eq('text/plain')
      expect(body).to eq(['Method Not Allowed'])
    end

    it "answers 405 for a whitelisted method the action doesn't define" do
      post_only = Class.new(described_class) do
        def post
          [200, {}, 'post']
        end
      end
      fake_request = Struct.new(:request_method, :env, :session).new('GET', {}, {})
      status, headers, = post_only.new(flipper, fake_request).run
      expect(status).to eq(405)
      expect(headers['allow']).to eq('POST')
    end

    it 'will run get' do
      fake_request = Struct.new(:request_method, :env, :session).new('GET', {}, {})
      action = action_subclass.new(flipper, fake_request)
      expect(action.run).to eq([200, {}, 'get'])
    end

    it 'will run get for head' do
      fake_request = Struct.new(:request_method, :env, :session).new('HEAD', {}, {})
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
  end

  describe 'FeatureNameFromRoute' do
    let(:action_subclass) do
      Class.new(described_class) do |parent|
        include parent::FeatureNameFromRoute

        route %r{\A/features/(?<feature_name>.*)\Z}

        def get
          [200, { feature_name: feature_name }, 'get']
        end
      end
    end

    it 'decodes feature_name' do
      requested_feature_name = Rack::Utils.escape("team:side_pane")
      fake_request = Struct
                     .new(:request_method, :env, :session, :path_info)
                     .new('GET', {}, {}, "/features/#{requested_feature_name}")
      action = action_subclass.new(flipper, fake_request)
      expect(action.run).to eq([200, { feature_name: "team:side_pane" }, 'get'])
    end
  end
end
