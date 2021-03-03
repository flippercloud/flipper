require 'helper'

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

    it "won't run method that isn't whitelisted" do
      fake_request = Struct.new(:request_method, :env, :session).new('NOOOOPE', {}, {})
      action = action_subclass.new(flipper, fake_request)
      expect do
        action.run
      end.to raise_error(Flipper::UI::RequestMethodNotSupported)
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

  describe 'Authorization' do
    subject(:run) { action_subclass.new(flipper, fake_request).run }

    let(:action_subclass) do
      Class.new(described_class) do
        def get
          [200, {}, 'get']
        end
      end
    end
    let(:fake_request) { Struct.new(:request_method, :env, :session).new('GET', {}, {}) }
    let(:test_auth_double) { double(present?: true) }

    before do
      @original_auth = Flipper::UI.configuration.authorization
      Flipper::UI.configuration.authorization = test_auth_double
      expect(test_auth_double).to receive(:call).with(action: 'get', request: fake_request) { auth_state }
    end

    after do
      Flipper::UI.configuration.authorization = @original_auth
    end

    context 'when authorized' do
      let(:auth_state) { double(permitted: true) }

      it 'will run get' do
        is_expected.to eq([200, {}, 'get'])
      end
    end

    context 'when not authorized' do
      let(:message) { 'Action not permitted' }
      let(:auth_state) { double(permitted: false, message: message) }

      it 'will run get' do
        expect(run.first).to eq(403)
        expect(run.last.first).to include(message)
      end
    end
  end
end
