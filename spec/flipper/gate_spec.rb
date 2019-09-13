# frozen_string_literal: true

require 'helper'

RSpec.describe Flipper::Gate do
  subject do
    described_class.new
  end

  let(:feature_name) { :stats }

  describe '#inspect' do
    context 'with subclass' do
      subject do
        subclass.new
      end

      let(:subclass) do
        Class.new(described_class) do
          def name
            :name
          end

          def key
            :key
          end

          def data_type
            :set
          end
        end
      end

      it 'includes attributes' do
        string = subject.inspect
        expect(string).to include(subject.object_id.to_s)
        expect(string).to include('name=:name')
        expect(string).to include('key=:key')
        expect(string).to include('data_type=:set')
      end
    end
  end
end
