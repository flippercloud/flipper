require 'helper'

RSpec.describe Flipper::UI::Actions::PercentageOfTimeGate do
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

  describe 'POST /features/:feature/percentage_of_time' do
    context 'with valid value' do
      before do
        post 'features/search/percentage_of_time',
             { 'value' => '24', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'enables the feature' do
        expect(flipper[:search].percentage_of_time_value).to be(24)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['Location']).to eq('/features/search')
      end
    end

    context 'with invalid value' do
      before do
        post 'features/search/percentage_of_time',
             { 'value' => '555', 'authenticity_token' => token },
             'rack.session' => session
      end

      it 'does not change value' do
        expect(flipper[:search].percentage_of_time_value).to be(0)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['Location']).to eq('/features/search?error=Invalid+percentage+of+time+value%3A+value+must+be+a+positive+number+less+than+or+equal+to+100%2C+but+was+555')
      end
    end
  end
end
