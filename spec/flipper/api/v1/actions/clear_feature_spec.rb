require 'helper'

RSpec.describe Flipper::Api::V1::Actions::ClearFeature do
  let(:app) { build_api(flipper) }

  describe 'clear' do
    before do
      Flipper.register(:admins) {}
      actor_class = Struct.new(:flipper_id)
      actor22 = actor_class.new('22')

      feature = flipper[:my_feature]
      feature.enable flipper.boolean
      feature.enable flipper.group(:admins)
      feature.enable flipper.actor(actor22)
      feature.enable flipper.actors(25)
      feature.enable flipper.time(45)

      post '/features/my_feature/clear'
    end

    it 'clears feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].off?).to be_truthy
    end

    it 'returns decorated feature with default config' do
      defaults = flipper.adapter.default_config
      expect(json_response['key']).to eq('my_feature')
      expect(json_response['state']).to eq('off')

      by_keys = json_response['gates'].each_with_object({}) { |gate, acc|
        acc[gate['key']] = gate
      }

      expect(by_keys['boolean']['value']).to be(nil)
      expect(by_keys['percentage_of_actors']['value']).to be(nil)
      expect(by_keys['percentage_of_time']['value']).to be(nil)
      expect(by_keys['groups']['value']).to eq([])
      expect(by_keys['actors']['value']).to eq([])
    end
  end
end
