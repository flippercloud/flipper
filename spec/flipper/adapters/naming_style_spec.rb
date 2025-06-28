require "flipper/adapters/naming_style"

RSpec.describe Flipper::Adapters::NamingStyle do
  it_should_behave_like "a flipper adapter" do
    let(:format) { /.*/ }
    let(:memory) { Flipper::Adapters::Memory.new }
    let(:adapter) { described_class.new(memory, format) }

    subject { adapter }

    describe "#initialize" do
      it "accepts a regex" do
        expect { described_class.new(memory, format) }.not_to raise_error
      end

      it "accepts a symbol" do
        [:camel, :snake, :kebab, :screaming_snake].each do |format|
          expect { described_class.new(memory, format) }.not_to raise_error
        end
      end

      it "raises an error if the format is an unknown symbol" do
        expect { described_class.new(memory, :Pascal) }.to raise_error(ArgumentError)
      end
    end

    describe "#add" do
      {
        /\A(breaker|feature)\// => {
          valid: %w[breaker/search feature/search],
          invalid: %w[search breaker_search breaker],
        },
        camel: {
          valid: %w[Camel CamelCase SCREAMINGCamelCase CamelCase1 Camel1Case],
          invalid: %w[snake_case Camel-Kebab lowercase],
        },
        snake: {
          valid: %w[lower snake_case snake_case_1],
          invalid: %w[CamelCase cobraCase double__underscore],
        },
        kebab: {
          valid: %w[kebab kebab-case kebab-case-1 htt-party],
          invalid: %w[CamelCase CamelCase1 double__dash],
        },
        screaming_snake: {
          valid: %w[SCREAMING SCREAMING_SNAKE SCREAMING_SNAKE_1 HTTP_THING],
          invalid: %w[CamelCase CamelCase1 double__underscore],
        }
      }.each do |format, examples|
        context "with format=#{format.inspect}" do
          let(:format) { format }

          examples[:valid].each do |feature|
            it "adds feature named #{feature}" do
              expect(subject.add(flipper[feature])).to eq(true)
              expect(subject.features).to eq(Set[feature])
            end
          end

          examples[:invalid].each do |feature|
            it "raises an error for feature named #{feature}" do
              expect { adapter.add(flipper[feature]) }.to raise_error(Flipper::Adapters::NamingStyle::InvalidFormat)
              expect(subject.features).to eq(Set[])
            end
          end
        end
      end
    end
  end
end
