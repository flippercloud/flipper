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

  describe 'POST /features/:feature/expression' do
    context 'with enable operation' do
      before do
        flipper.disable :search
        post 'features/search/expression',
             {
               'operation' => 'enable',
               'expression_property' => 'plan',
               'expression_operator' => 'eq',
               'expression_value' => 'basic',
               'authenticity_token' => token
             },
             'rack.session' => session
      end

      it 'enables the feature with expression' do
        expect(flipper.feature(:search).enabled_gate_names).to include(:expression)
      end

      it 'sets the correct expression' do
        expected_expression = { "Equal" => [{ "Property" => ["plan"] }, "basic"] }
        expect(flipper.feature(:search).expression.value).to eq(expected_expression)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/search')
      end
    end

    context 'with disable operation' do
      before do
        expression = Flipper::Expression.build({ "Equal" => [{ "Property" => ["plan"] }, "basic"] })
        flipper.enable_expression :search, expression
        post 'features/search/expression',
             {
               'operation' => 'disable',
               'authenticity_token' => token
             },
             'rack.session' => session
      end

      it 'disables the expression gate' do
        expect(flipper.feature(:search).enabled_gate_names).not_to include(:expression)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/search')
      end
    end





    context 'with invalid expression that causes exception' do
      it 'lets exception bubble up' do
        flipper.disable :search
        expect { post 'features/search/expression',
               {
                 'operation' => 'enable',
                 'expression_property' => 'plan',
                 'expression_operator' => 'invalid_op',
                 'expression_value' => 'basic',
                 'authenticity_token' => token
               },
               'rack.session' => session }.to raise_error(ArgumentError, /cannot be converted into an expression/)
      end
    end

    ['eq', 'ne', 'gt', 'gte', 'lt', 'lte'].each do |operator|
      context "with #{operator} operator" do
        before do
          flipper.disable :search
          post 'features/search/expression',
               {
                 'operation' => 'enable',
                 'expression_property' => 'plan',
                 'expression_operator' => operator,
                 'expression_value' => 'basic',
                 'authenticity_token' => token
               },
               'rack.session' => session
        end

        it 'successfully creates expression' do
          expect(flipper.feature(:search).enabled_gate_names).to include(:expression)
        end

        it 'redirects back to feature' do
          expect(last_response.status).to be(302)
          expect(last_response.headers['location']).to eq('/features/search')
        end
      end
    end

    context 'with space in feature name' do
      before do
        flipper.disable "sp ace"
        post 'features/sp%20ace/expression',
             {
               'operation' => 'enable',
               'expression_property' => 'plan',
               'expression_operator' => 'eq',
               'expression_value' => 'basic',
               'authenticity_token' => token
             },
             'rack.session' => session
      end

      it 'enables the feature with expression' do
        expect(flipper.feature("sp ace").enabled_gate_names).to include(:expression)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/sp+ace')
      end
    end

    context 'with complex any expression' do
      before do
        flipper.disable :search
        post 'features/search/expression',
             {
               'operation' => 'enable',
               'complex_expression_type' => 'any',
               'complex_expressions' => {
                 '0' => {
                   'property' => 'plan',
                   'operator' => 'eq',
                   'value' => 'basic'
                 },
                 '1' => {
                   'property' => 'premium',
                   'operator' => 'eq',
                   'value' => 'true'
                 }
               },
               'authenticity_token' => token
             },
             'rack.session' => session
      end

      it 'enables the feature with any expression' do
        expect(flipper.feature(:search).enabled_gate_names).to include(:expression)
      end

      it 'sets the correct any expression' do
        expected_expression = {
          "Any" => [
            { "Equal" => [{ "Property" => ["plan"] }, "basic"] },
            { "Equal" => [{ "Property" => ["premium"] }, "true"] }
          ]
        }
        expect(flipper.feature(:search).expression.value).to eq(expected_expression)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/search')
      end
    end

    context 'with complex all expression' do
      before do
        flipper.disable :search
        post 'features/search/expression',
             {
               'operation' => 'enable',
               'complex_expression_type' => 'all',
               'complex_expressions' => {
                 '0' => {
                   'property' => 'plan',
                   'operator' => 'eq',
                   'value' => 'premium'
                 },
                 '1' => {
                   'property' => 'age',
                   'operator' => 'gte',
                   'value' => '18'
                 }
               },
               'authenticity_token' => token
             },
             'rack.session' => session
      end

      it 'enables the feature with all expression' do
        expect(flipper.feature(:search).enabled_gate_names).to include(:expression)
      end

      it 'sets the correct all expression' do
        expected_expression = {
          "All" => [
            { "Equal" => [{ "Property" => ["plan"] }, "premium"] },
            { "GreaterThanOrEqualTo" => [{ "Property" => ["age"] }, "18"] }
          ]
        }
        expect(flipper.feature(:search).expression.value).to eq(expected_expression)
      end

      it 'redirects back to feature' do
        expect(last_response.status).to be(302)
        expect(last_response.headers['location']).to eq('/features/search')
      end
    end
  end



  describe 'expression parameter parsing' do
    let(:action) { described_class.new(flipper, double('request')) }

    before do
      allow(Flipper::UI.configuration).to receive(:expression_properties).and_return({
        'age' => { type: 'number' },
        'premium' => { type: 'boolean' },
        'plan' => { type: 'string' }
      })
    end

    it 'supports all comparison operators' do
      operators = {
        'eq' => 'Equal',
        'ne' => 'NotEqual',
        'gt' => 'GreaterThan',
        'gte' => 'GreaterThanOrEqualTo',
        'lt' => 'LessThan',
        'lte' => 'LessThanOrEqualTo'
      }

      operators.each do |op, expression_type|
        allow(action).to receive(:params).and_return({
          'expression_property' => 'age',
          'expression_operator' => op,
          'expression_value' => '25'
        })

        result = action.send(:parse_expression_params)
        expect(result).to eq({
          expression_type => [{ "Property" => ["age"] }, 25]
        })
      end
    end

    it 'converts numeric values' do
      allow(action).to receive(:params).and_return({
        'expression_property' => 'age',
        'expression_operator' => 'gt',
        'expression_value' => '25'
      })

      result = action.send(:parse_expression_params)
      expect(result['GreaterThan'][1]).to eq(25)
    end

    it 'converts boolean values' do
      allow(action).to receive(:params).and_return({
        'expression_property' => 'premium',
        'expression_operator' => 'eq',
        'expression_value' => 'true'
      })

      result = action.send(:parse_expression_params)
      expect(result['Equal'][1]).to eq(true)
    end

    it 'handles string values' do
      allow(action).to receive(:params).and_return({
        'expression_property' => 'plan',
        'expression_operator' => 'eq',
        'expression_value' => 'basic'
      })

      result = action.send(:parse_expression_params)
      expect(result['Equal'][1]).to eq('basic')
    end

    it 'parses complex any expressions' do
      allow(action).to receive(:params).and_return({
        'complex_expression_type' => 'any',
        'complex_expressions' => {
          '0' => {
            'property' => 'plan',
            'operator' => 'eq',
            'value' => 'basic'
          },
          '1' => {
            'property' => 'premium',
            'operator' => 'eq',
            'value' => 'true'
          }
        }
      })

      result = action.send(:parse_expression_params)
      expect(result).to eq({
        "Any" => [
          { "Equal" => [{ "Property" => ["plan"] }, "basic"] },
          { "Equal" => [{ "Property" => ["premium"] }, true] }
        ]
      })
    end

    it 'parses complex all expressions' do
      allow(action).to receive(:params).and_return({
        'complex_expression_type' => 'all',
        'complex_expressions' => {
          '0' => {
            'property' => 'age',
            'operator' => 'gte',
            'value' => '18'
          },
          '1' => {
            'property' => 'plan',
            'operator' => 'ne',
            'value' => 'free'
          }
        }
      })

      result = action.send(:parse_expression_params)
      expect(result).to eq({
        "All" => [
          { "GreaterThanOrEqualTo" => [{ "Property" => ["age"] }, 18] },
          { "NotEqual" => [{ "Property" => ["plan"] }, "free"] }
        ]
      })
    end

    it 'skips empty expressions in complex forms' do
      allow(action).to receive(:params).and_return({
        'complex_expression_type' => 'any',
        'complex_expressions' => {
          '0' => {
            'property' => 'plan',
            'operator' => 'eq',
            'value' => 'basic'
          },
          '1' => {
            'property' => '',
            'operator' => 'eq',
            'value' => 'something'
          },
          '2' => {
            'property' => 'premium',
            'operator' => '',
            'value' => 'true'
          }
        }
      })

      result = action.send(:parse_expression_params)
      expect(result).to eq({
        "Any" => [
          { "Equal" => [{ "Property" => ["plan"] }, "basic"] }
        ]
      })
    end

    it 'raises error for unknown complex expression type' do
      allow(action).to receive(:params).and_return({
        'complex_expression_type' => 'unknown',
        'complex_expressions' => {}
      })

      expect { action.send(:parse_expression_params) }.to raise_error('Unknown complex expression type: unknown')
    end
  end
end
