RSpec.describe Flipper::Api::V1::Actions::Import do
  let(:app) { build_api(flipper) }

  describe 'post' do
    context 'succesful request' do
      before do
        flipper.enable(:search)
        flipper.disable(:adios)

        source_flipper = build_flipper
        source_flipper.disable(:search)
        source_flipper.enable_actor(:google_analytics, Flipper::Actor.new("User;1"))
        source_flipper.enable(:analytics, Flipper.property(:plan).eq("basic"))

        export = source_flipper.export

        post '/import', export.contents, 'CONTENT_TYPE' => 'application/json'
      end

      it 'responds 204' do
        expect(last_response.status).to eq(204)
      end

      it 'imports features' do
        expect(flipper[:search].boolean_value).to be(false)
        expect(flipper[:google_analytics].actors_value).to eq(Set["User;1"])
        expect(flipper[:analytics].expression_value).to eq({"Equal"=>[{"Property"=>["plan"]}, {"String"=>["basic"]}]})
        expect(flipper.features.map(&:key)).to eq(["search", "google_analytics", "analytics"])
      end
    end

    context 'empty request' do
      before do
        flipper.enable(:search)
        flipper.disable(:adios)

        source_flipper = build_flipper
        export = source_flipper.export

        post '/import', export.contents, 'CONTENT_TYPE' => 'application/json'
      end

      it 'responds 204' do
        expect(last_response.status).to eq(204)
      end

      it 'removes all features' do
        expect(flipper.features.map(&:key)).to eq([])
      end
    end

    context 'bad request' do
      before do
        post '/import'
      end

      it 'returns correct status code' do
        expect(last_response.status).to eq(422)
      end

      it 'returns formatted error' do
        expected = {
          'code' => 6,
          'message' => 'Import invalid.',
          'more_info' => api_error_code_reference_url,
        }
        expect(json_response).to eq(expected)
      end
    end
  end
end
