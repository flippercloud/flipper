require 'helper'
require 'flipper/adapters/http'
require 'webmock/rspec'

RSpec.describe Flipper::Adapters::Http do

  subject { described_class.new('http://app.com/mount-point') }

  let(:feature) { instance_double('Feature', key: 'feature_panel') }

  describe '#get' do
    it 'requests correct url' do
      stub_request(:get, %r{\Ahttp://app.com*}).to_return(body: fixture_file('feature.json'))
      subject.get(feature)
      expect(a_request(:get, 'http://app.com/mount-point/api/v1/features/feature_panel')).to have_been_made.once
    end

    it 'returns hash according to adapter spec' do
      stub_request(:get, %r{\Ahttp://app.com*}).to_return(body: fixture_file('feature.json'))
      response = subject.get(feature)
      expect(response).to eq(
        boolean: true,
        groups: Set.new,
        actors: Set.new,
        percentage_of_actors: 0,
        percentage_of_time: 0
      )
    end
  end

  describe '#add' do
    it 'requests correct url' do
      stub_request(:post, %r{\Ahttp://app.com*}).to_return(body: fixture_file('feature.json'))
      subject.add(feature)
      expect(a_request(:post, 'http://app.com/mount-point/api/v1/features')).to have_been_made.once
    end

    it 'returns true on succesful request' do
      stub_request(:post, %r{\Ahttp://app.com*}).to_return(body: fixture_file('feature.json'))
      expect(subject.add(feature)).to be true
    end

    it 'returns false on unsuccesful request' do
      stub_request(:post, %r{\Ahttp://app.com*}).to_return(status: 500)
      expect(subject.add(feature)).to be false
    end
  end

  describe '#features' do
    it 'requests correct url' do
      stub_request(:get, %r{\Ahttp://app.com*}).to_return(body: fixture_file('features.json'))
      subject.features
      expect(a_request(:get, 'http://app.com/mount-point/api/v1/features')).to have_been_made.once
    end

    it 'returns set of feature keys' do
      stub_request(:get, %r{\Ahttp://app.com*}).to_return(body: fixture_file('features.json'))
      response = subject.features
      expect(response).to eq(%w(my_feature).to_set)
    end
  end

  describe '#remove' do
    it 'requests correct url' do
      stub_request(:delete, %r{\Ahttp://app.com*})
      subject.remove(feature)
      expect(a_request(:delete, 'http://app.com/mount-point/api/v1/features/feature_panel')).to have_been_made.once
    end

    it 'returns true on succesful request' do
      stub_request(:delete, %r{\Ahttp://app.com*})
      expect(subject.remove(feature)).to be true
    end

    it 'returns false on unsuccessful request' do
      stub_request(:delete, %r{\Ahttp://app.com*}).to_return(status: 500)
      expect(subject.remove(feature)).to be false
    end
  end

  describe '#enable' do
    context 'groups gate' do
      let(:gate) { instance_double('Gate', name: :group, key: :groups) }
      let(:feature) { instance_double('Feature', key: :admin) }
      let(:thing) { instance_double('Thing', value: 'admins') }

      describe '#enable' do
        it 'requests correct url' do
          stub_request(:post, %r{\Ahttp://app.com*})
          subject.enable(feature, gate, thing)
          expect(a_request(:post, 'http://app.com/mount-point/api/v1/features/admin/groups').with(body: { name: 'admins' }.to_json)).to have_been_made.once
        end

        it 'returns true on successful request' do
          stub_request(:post, %r{\Ahttp://app.com*})
          expect(subject.enable(feature, gate, thing)).to be true
        end

        it 'returns false on unsuccesful request' do
          stub_request(:post, %r{\Ahttp://app.com*}).to_return(status: 500)
          expect(subject.enable(feature, gate, thing)).to be false
        end
      end

      describe '#disable' do
        it 'requests correct url' do
          stub_request(:delete, %r{\Ahttp://app.com*})
          subject.disable(feature, gate, thing)
          expect(a_request(:delete, 'http://app.com/mount-point/api/v1/features/admin/groups')).to have_been_made.once
        end

        it 'returns true on successful request' do
          stub_request(:delete, %r{\Ahttp://app.com*})
          expect(subject.disable(feature, gate, thing)).to be true
        end

        it 'returns false on unsuccesful request' do
          stub_request(:delete, %r{\Ahttp://app.com*}).to_return(status: 500)
          expect(subject.disable(feature, gate, thing)).to be false
        end

      end
    end

    context 'actors gate' do
      let(:gate) { instance_double('Gate', name: :actor, key: :actors) }
      let(:feature) { instance_double('Feature', key: :admin) }
      let(:thing) { instance_double('Thing', value: 'user:22') }

      describe '#enable' do
        it 'requests correct url' do
          stub_request(:post, %r{\Ahttp://app.com*})
          subject.enable(feature, gate, thing)
          expect(a_request(:post, 'http://app.com/mount-point/api/v1/features/admin/actors').with(body: { flipper_id: 'user:22' }.to_json)).to have_been_made.once
        end

        it 'returns true on succesful request' do
          stub_request(:post, %r{\Ahttp://app.com*})
          response = subject.enable(feature, gate, thing)
          expect(response).to be true
        end

        it 'returns false on unsuccesful request' do
          stub_request(:post, %r{\Ahttp://app.com*}).to_return(status: 500)
          response = subject.enable(feature, gate, thing)
          expect(response).to be false
        end
      end

      describe '#disable' do
        it 'requests correct url' do
          stub_request(:delete, %r{\Ahttp://app.com*})
          subject.disable(feature, gate, thing)
          expect(a_request(:delete, 'http://app.com/mount-point/api/v1/features/admin/actors')).to have_been_made.once
        end

        it 'returns true on succesful request' do
          stub_request(:delete, %r{\Ahttp://app.com*})
          response = subject.disable(feature, gate, thing)
          expect(response).to be true
        end

        it 'returns false on unsuccesful request' do
          stub_request(:delete, %r{\Ahttp://app.com*}).to_return(status: 500)
          response = subject.disable(feature, gate, thing)
          expect(response).to be false
        end
      end
    end

    context 'boolean gate' do
      let(:gate) { instance_double('Gate', name: :boolean, key: :boolean) }
      let(:feature) { instance_double('Feature', key: :admin) }
      let(:thing) { instance_double('Thing', value: 'user:22') }

      describe '#enable' do
        it 'requests correct url' do
          stub_request(:post, %r{\Ahttp://app.com*})
          subject.enable(feature, gate, thing)
          expect(a_request(:post, 'http://app.com/mount-point/api/v1/features/admin/boolean').with(body: {})).to have_been_made.once
        end

        it 'returns true on succesful request' do
          stub_request(:post, %r{\Ahttp://app.com*})
          response = subject.enable(feature, gate, thing)
          expect(response).to be true
        end

        it 'returns false on succesful request' do
          stub_request(:post, %r{\Ahttp://app.com*}).to_return(status: 500)
          response = subject.enable(feature, gate, thing)
          expect(response).to be false
        end
      end

      describe '#disable' do
        it 'requests correct url' do
          stub_request(:delete, %r{\Ahttp://app.com*})
          subject.disable(feature, gate, thing)
          expect(a_request(:delete, 'http://app.com/mount-point/api/v1/features/admin/boolean').with(body: {})).to have_been_made.once
        end

        it 'returns true on succesful request' do
          stub_request(:delete, %r{\Ahttp://app.com*})
          response = subject.disable(feature, gate, thing)
          expect(response).to be true
        end

        it 'returns false on successful request' do
          stub_request(:delete, %r{\Ahttp://app.com*}).to_return(status: 500)
          response = subject.disable(feature, gate, thing)
          expect(response).to be false
        end
      end
    end

    context 'percentage of actors gate' do
      let(:gate) { instance_double('Gate', key: :percentage_of_actors) }
      let(:feature) { instance_double('Feature', key: :admin) }
      let(:thing) { instance_double('Thing', value: 10) }

      describe '#enable' do
        it 'requests correct url' do
          stub_request(:post, %r{\Ahttp://app.com*})
          subject.enable(feature, gate, thing)
          expect(a_request(:post, 'http://app.com/mount-point/api/v1/features/admin/percentage_of_actors').with(body: { percentage: '10' }.to_json)).to have_been_made.once
        end

        it 'returns true on succesful request' do
          stub_request(:post, %r{\Ahttp://app.com*})
          response = subject.enable(feature, gate, thing)
          expect(response).to be true
        end

        it 'returns false on succesful request' do
          stub_request(:post, %r{\Ahttp://app.com*}).to_return(status: 500)
          response = subject.enable(feature, gate, thing)
          expect(response).to be false
        end
      end

      describe '#disable' do
        it 'requests correct url' do
          stub_request(:delete, %r{\Ahttp://app.com*})
          subject.disable(feature, gate, thing)
          expect(a_request(:delete, 'http://app.com/mount-point/api/v1/features/admin/percentage_of_actors').with(body: {})).to have_been_made.once
        end

        it 'returns true on succesful request' do
          stub_request(:delete, %r{\Ahttp://app.com*})
          response = subject.disable(feature, gate, thing)
          expect(response).to be true
        end

        it 'returns false on succesful request' do
          stub_request(:delete, %r{\Ahttp://app.com*}).to_return(status: 500)
          response = subject.disable(feature, gate, thing)
          expect(response).to be false
        end
      end
    end

    context 'percentage of time gate' do
      let(:gate) { instance_double('Gate', key: :percentage_of_time) }
      let(:feature) { instance_double('Feature', key: :admin) }
      let(:thing) { instance_double('Thing', value: 20) }

      describe '#enable' do
        it 'requests correct url' do
          stub_request(:post, %r{\Ahttp://app.com*})
          subject.enable(feature, gate, thing)
          expect(a_request(:post, 'http://app.com/mount-point/api/v1/features/admin/percentage_of_time').with(body: { percentage: '20' }.to_json)).to have_been_made.once

        end

        it 'returns true on succesful request' do
          stub_request(:post, %r{\Ahttp://app.com*})
          response = subject.enable(feature, gate, thing)
          expect(response).to be true
        end

        it 'returns false on succesful request' do
          stub_request(:post, %r{\Ahttp://app.com*}).to_return(status: 500)
          response = subject.enable(feature, gate, thing)
          expect(response).to be false
        end
      end

      describe '#disable' do
        it 'requests correct url' do
          stub_request(:delete, %r{\Ahttp://app.com*})
          subject.disable(feature, gate, thing)
          expect(a_request(:delete, 'http://app.com/mount-point/api/v1/features/admin/percentage_of_time').with(body: {})).to have_been_made.once
        end

        it 'returns true on succesful request' do
          stub_request(:delete, %r{\Ahttp://app.com*})
          response = subject.disable(feature, gate, thing)
          expect(response).to be true
        end

        it 'returns false on succesful request' do
          stub_request(:delete, %r{\Ahttp://app.com*}).to_return(status: 500)
          response = subject.disable(feature, gate, thing)
          expect(response).to be false
        end
      end
    end

    describe 'configuration' do
      before do
        stub_request(:get, %r{\Ahttp://app.com*}).to_return(body: fixture_file('feature.json'))

        described_class.configure do |c|
          c.headers = { 'X-Custom-Header' => 'foo' }
          c.basic_auth = {'username' => 'password'}
        end
      end

      subject { described_class.new('http://app.com/mount-point') }

      it 'allows client to set request headers' do
        subject.get(feature)
        expect(a_request(:get, 'http://app.com/mount-point/api/v1/features/feature_panel').with(headers: { 'X-Custom-Header' => 'foo'})).to have_been_made.once
      end

      it 'allows client to set basic auth' do
        subject.get(feature)
        expect(a_request(:get, 'http://app.com/mount-point/api/v1/features/feature_panel').with(basic_auth: [ 'username', 'password' ])).to have_been_made.once
      end
    end
  end

  def fixture_file(name)
    fixtures_path = File.expand_path('../../../fixtures', __FILE__)
    File.new(fixtures_path + '/' + name)
  end
end
