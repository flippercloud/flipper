RSpec.describe Flipper::UI::Actions::Features do
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

  describe "POST /settings/export" do
    before do
      flipper.enable_percentage_of_actors :search, 10
      flipper.enable_percentage_of_time :search, 15
      flipper.enable_actor :search, Flipper::Actor.new('User;1')
      flipper.enable_actor :search, Flipper::Actor.new('User;100')
      flipper.enable_group :search, :admins
      flipper.enable_group :search, :employees
      flipper.enable :plausible
      flipper.disable :google_analytics
      flipper.enable :analytics, Flipper.property(:plan).eq("basic")

      post '/settings/export',
        {'authenticity_token' => token},
        'rack.session' => session
    end

    it 'responds with success' do
      expect(last_response.status).to be(200)
    end

    it 'sets content disposition' do
      expect(last_response.headers['content-disposition']).to match(/Attachment;filename=flipper_memory_[0-9]*\.json/)
    end

    it 'renders json' do
      data = JSON.parse(last_response.body)
      expect(last_response.headers['content-type']).to eq('application/json')
      expect(data['version']).to eq(1)
      expect(data['features']).to eq({
        "analytics" => {"boolean"=>nil, "expression"=>{"Equal"=>[{"Property"=>["plan"]}, "basic"]}, "groups"=>[], "actors"=>[], "percentage_of_actors"=>nil, "percentage_of_time"=>nil},
        "search"=> {"boolean"=>nil, "expression"=>nil, "groups"=>["admins", "employees"], "actors"=>["User;1", "User;100"], "percentage_of_actors"=>"10", "percentage_of_time"=>"15"},
        "plausible"=> {"boolean"=>"true", "expression"=>nil, "groups"=>[], "actors"=>[], "percentage_of_actors"=>nil, "percentage_of_time"=>nil},
        "google_analytics"=> {"boolean"=>nil, "expression"=>nil, "groups"=>[], "actors"=>[], "percentage_of_actors"=>nil, "percentage_of_time"=>nil},
      })
    end
  end
end
