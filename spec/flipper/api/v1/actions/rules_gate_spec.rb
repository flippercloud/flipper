require 'helper'

RSpec.describe Flipper::Api::V1::Actions::RulesGate do
  let(:app) { build_api(flipper) }
  let(:actor) {
    Flipper::Actor.new('1', {
      "plan" => "basic",
      "age" => 21,
    })
  }
  let(:rule) {
    Flipper::Rule.new(
      {"type" => "property", "value" => "plan"},
      {"type" => "operator", "value" => "eq"},
      {"type" => "string", "value" => "basic"}
    )
  }

  describe 'enable' do
    before do
      flipper[:my_feature].disable_rule(rule)
      post '/features/my_feature/rules', JSON.dump(rule.value), "CONTENT_TYPE" => "application/json"
    end

    it 'enables feature for rule' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].enabled?(actor)).to be_truthy
      expect(flipper[:my_feature].enabled_gate_names).to eq([:rule])
    end

    it 'returns decorated feature with rule enabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'rules' }
      expect(gate['value']).to eq([rule.value])
    end
  end

  describe 'disable' do
    before do
      flipper[:my_feature].enable_rule(rule)
      delete '/features/my_feature/rules', JSON.dump(rule.value), "CONTENT_TYPE" => "application/json"
    end

    it 'disables rule for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].enabled?(actor)).to be_falsy
      expect(flipper[:my_feature].enabled_gate_names).to be_empty
    end

    it 'returns decorated feature with rule gate disabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'rules' }
      expect(gate['value']).to be_empty
    end
  end

  describe 'enable feature with slash in name' do
    before do
      flipper["my/feature"].disable_rule(rule)
      post '/features/my/feature/rules', JSON.dump(rule.value), "CONTENT_TYPE" => "application/json"
    end

    it 'enables feature for rule' do
      expect(last_response.status).to eq(200)
      expect(flipper["my/feature"].enabled?(actor)).to be_truthy
      expect(flipper["my/feature"].enabled_gate_names).to eq([:rule])
    end

    it 'returns decorated feature with rule enabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'rules' }
      expect(gate['value']).to eq([rule.value])
    end
  end

  describe 'enable feature with space in name' do
    before do
      flipper["sp ace"].disable_rule(rule)
      post '/features/sp%20ace/rules', JSON.dump(rule.value), "CONTENT_TYPE" => "application/json"
    end

    it 'enables feature for rule' do
      expect(last_response.status).to eq(200)
      expect(flipper["sp ace"].enabled?(actor)).to be_truthy
      expect(flipper["sp ace"].enabled_gate_names).to eq([:rule])
    end

    it 'returns decorated feature with rule enabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'rules' }
      expect(gate['value']).to eq([rule.value])
    end
  end

  describe 'enable missing type parameter' do
    before do
      data = rule.value
      data.delete("type")
      post '/features/my_feature/rules', JSON.dump(data), "CONTENT_TYPE" => "application/json"
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_rule_type_invalid_response)
    end
  end

  describe 'disable missing type parameter' do
    before do
      data = rule.value
      data.delete("type")
      delete '/features/my_feature/rules'
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_rule_type_invalid_response)
    end
  end

  describe 'enable missing value parameter' do
    before do
      data = rule.value
      data.delete("value")
      post '/features/my_feature/rules', JSON.dump(data), "CONTENT_TYPE" => "application/json"
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_rule_value_invalid_response)
    end
  end

  describe 'disable missing value parameter' do
    before do
      data = rule.value
      data.delete("value")
      delete '/features/my_feature/rules', JSON.dump(data), "CONTENT_TYPE" => "application/json"
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_rule_value_invalid_response)
    end
  end

  describe 'enable nil type parameter' do
    before do
      data = rule.value
      data["type"] = nil
      post '/features/my_feature/rules', JSON.dump(data), "CONTENT_TYPE" => "application/json"
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_rule_type_invalid_response)
    end
  end

  describe 'disable nil type parameter' do
    before do
      data = rule.value
      data["type"] = nil
      delete '/features/my_feature/rules', JSON.dump(data), "CONTENT_TYPE" => "application/json"
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_rule_type_invalid_response)
    end
  end

  describe 'enable nil value parameter' do
    before do
      data = rule.value
      data["value"] = nil
      post '/features/my_feature/rules', JSON.dump(data), "CONTENT_TYPE" => "application/json"
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_rule_value_invalid_response)
    end
  end

  describe 'disable nil value parameter' do
    before do
      data = rule.value
      data["value"] = nil
      delete '/features/my_feature/rules', JSON.dump(data), "CONTENT_TYPE" => "application/json"
    end

    it 'returns correct error response' do
      expect(last_response.status).to eq(422)
      expect(json_response).to eq(api_rule_value_invalid_response)
    end
  end

  describe 'enable missing feature' do
    before do
      post '/features/my_feature/rules', JSON.dump(rule.value), "CONTENT_TYPE" => "application/json"
    end

    it 'enables rule for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].enabled?(actor)).to be_truthy
      expect(flipper[:my_feature].enabled_gate_names).to eq([:rule])
    end

    it 'returns decorated feature with rule enabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'rules' }
      expect(gate['value']).to eq([rule.value])
    end
  end

  describe 'disable missing feature' do
    before do
      delete '/features/my_feature/rules', JSON.dump(rule.value), "CONTENT_TYPE" => "application/json"
    end

    it 'disables rule for feature' do
      expect(last_response.status).to eq(200)
      expect(flipper[:my_feature].enabled?(actor)).to be_falsy
      expect(flipper[:my_feature].enabled_gate_names).to be_empty
    end

    it 'returns decorated feature with rule gate disabled' do
      gate = json_response['gates'].find { |gate| gate['key'] == 'rules' }
      expect(gate['value']).to be_empty
    end
  end
end
