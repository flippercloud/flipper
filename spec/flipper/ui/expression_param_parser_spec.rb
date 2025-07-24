RSpec.describe Flipper::UI::ExpressionParamParser do
  describe '#parse' do
    context 'with nil expression' do
      it 'returns empty hash' do
        parser = described_class.new(nil)
        expect(parser.parse).to eq({})
      end
    end

    context 'with empty string expression' do
      it 'raises InvalidJSONError' do
        parser = described_class.new('')
        expect { parser.parse }.to raise_error(Flipper::UI::ExpressionParamParser::InvalidJSONError)
      end
    end

    context 'with valid JSON string' do
      it 'parses JSON string correctly' do
        json_string = '{"Equal": [{"Property": ["userId"]}, {"String": ["123"]}]}'
        parser = described_class.new(json_string)
        expected = {"Equal" => [{"Property" => ["userId"]}, {"String" => ["123"]}]}
        expect(parser.parse).to eq(expected)
      end
    end

    context 'with invalid JSON string' do
      it 'raises InvalidJSONError' do
        json_string = '{"invalid": json}'
        parser = described_class.new(json_string)
        expect { parser.parse }.to raise_error(Flipper::UI::ExpressionParamParser::InvalidJSONError)
      end
    end

    context 'with hash expression with type and args' do
      it 'converts to proper format' do
        expression = {
          'type' => 'Equal',
          'args' => {
            '0' => {'type' => 'Property', 'args' => {'0' => 'userId'}},
            '1' => {'type' => 'String', 'args' => {'0' => '123'}}
          }
        }
        parser = described_class.new(expression)
        expected = {"Equal" => [{"Property" => ["userId"]}, {"String" => ["123"]}]}
        expect(parser.parse).to eq(expected)
      end
    end

    context 'with nested hash expressions' do
      it 'converts nested expressions correctly' do
        expression = {
          'type' => 'Any',
          'args' => {
            '0' => {
              'type' => 'Equal',
              'args' => {
                '0' => {'type' => 'Property', 'args' => {'0' => 'userId'}},
                '1' => {'type' => 'String', 'args' => {'0' => '123'}}
              }
            },
            '1' => {
              'type' => 'Equal',
              'args' => {
                '0' => {'type' => 'Property', 'args' => {'0' => 'role'}},
                '1' => {'type' => 'String', 'args' => {'0' => 'admin'}}
              }
            }
          }
        }
        parser = described_class.new(expression)
        expected = {
          "Any" => [
            {"Equal" => [{"Property" => ["userId"]}, {"String" => ["123"]}]},
            {"Equal" => [{"Property" => ["role"]}, {"String" => ["admin"]}]}
          ]
        }
        expect(parser.parse).to eq(expected)
      end
    end

    context 'with hash without type and args' do
      it 'returns the hash unchanged' do
        expression = {"some" => "data"}
        parser = described_class.new(expression)
        expect(parser.parse).to eq(expression)
      end
    end

    context 'with primitive values in args' do
      it 'preserves primitive values' do
        expression = {
          'type' => 'Equal',
          'args' => {
            '0' => 'simple_string',
            '1' => 42
          }
        }
        parser = described_class.new(expression)
        expected = {"Equal" => ["simple_string", 42]}
        expect(parser.parse).to eq(expected)
      end
    end
  end
end
