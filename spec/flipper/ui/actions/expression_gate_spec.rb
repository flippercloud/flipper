RSpec.describe Flipper::UI::Actions::ExpressionGate do
  let(:token) do
    if Rack::Protection::AuthenticityToken.respond_to?(:random_token)
      Rack::Protection::AuthenticityToken.random_token
    else
      'a'
    end
  end
  let(:session) do
    { :csrf => token, 'csrf' => token, '_csrf_token' => token }
  end

  before do
    allow(Flipper::UI.configuration).to receive(:expressions_enabled).and_return(true)
  end

  describe 'POST /features/:feature/expression' do
    context 'with expressions disabled' do
      before do
        allow(Flipper::UI.configuration).to receive(:expressions_enabled).and_return(false)
        post 'features/search/expression',
             { 'operation' => 'enable', 'expression' => '{"Equal": [{"Property": ["userId"]}, {"String": ["123"]}]}', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'does not enable expression' do
        expect(flipper[:search].expression).to be_nil
      end

      it 'renders expressions disabled view' do
        expect(last_response.status).to be(200)
        expect(last_response.body).to include('Expression editing in the UI is disabled')
      end
    end

    context 'with enable operation' do
      context 'with valid expression' do
        before do
          flipper.disable :search
          post 'features/search/expression',
               { 'operation' => 'enable', 'expression' => '{"Equal": [{"Property": ["userId"]}, {"String": ["123"]}]}', 'authenticity_token' => token },
               'rack.session' => session
        end

        it 'enables expression on the feature' do
          expect(flipper[:search].expression).to be_truthy
        end

        it 'redirects back to feature' do
          expect(last_response.status).to be(302)
          expect(last_response.headers['location']).to eq('/features/search')
        end
      end

      context 'with space in feature name' do
        before do
          flipper.disable "sp ace"
          post 'features/sp%20ace/expression',
               { 'operation' => 'enable', 'expression' => '{"Equal": [{"Property": ["userId"]}, {"String": ["123"]}]}', 'authenticity_token' => token },
               'rack.session' => session
        end

        it 'updates feature' do
          expect(flipper["sp ace"].expression).to be_truthy
        end

        it 'redirects back to feature' do
          expect(last_response.status).to be(302)
          expect(last_response.headers['location']).to eq('/features/sp+ace')
        end
      end

      context 'with invalid JSON expression' do
        before do
          post 'features/search/expression',
               { 'operation' => 'enable', 'expression' => '{"invalid": json}', 'authenticity_token' => token },
               'rack.session' => session
        end

        it 'does not enable expression' do
          expect(flipper[:search].expression).to be_nil
        end

        it 'redirects back to feature with error' do
          expect(last_response.status).to be(302)
          expect(last_response.headers['location']).to include('/features/search?error=Expression+JSON+is+not+valid.')
        end
      end

      context 'with invalid expression structure' do
        before do
          post 'features/search/expression',
               { 'operation' => 'enable', 'expression' => '{"invalid_expression": []}', 'authenticity_token' => token },
               'rack.session' => session
        end

        it 'does not enable expression' do
          expect(flipper[:search].expression).to be_nil
        end

        it 'redirects back to feature with error' do
          expect(last_response.status).to be(302)
          expect(last_response.headers['location']).to include('/features/search?error=Expression+is+not+valid.')
        end
      end
    end

    context 'with disable operation' do
      before do
        flipper[:search].enable_expression Flipper::Expression.build({"Equal" => [{"Property" => ["userId"]}, {"String" => ["123"]}]})
        post 'features/search/expression',
             { 'operation' => 'disable', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'disables expression on the feature' do
        expect(flipper[:search].expression).to be_nil
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/search')
      end
    end
  end
end
