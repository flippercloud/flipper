require 'helper'
require 'flipper/adapters/http'
require 'webmock/rspec'

RSpec.describe Flipper::Adapters::Http do
  subject { described_class.new('http://app.com/mount-point') }

  context 'request routes' do
    describe '#get' do
      it 'requests correct url' do
        stub_request(:get, %r{\Ahttp://app.com*}).to_return(body: fixture_file('feature.json'))
        subject.get('name')
        expect(a_request(:get, 'http://app.com/mount-point/api/v1/features/name')).to have_been_made.once
      end

      it 'returns hash according to adapter spec' do
        stub_request(:get, %r{\Ahttp://app.com*}).to_return(body: fixture_file('feature.json'))
        response = subject.get('name')
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
        subject.add('name')
        expect(a_request(:post, 'http://app.com/mount-point/api/v1/features')).to have_been_made.once
      end

      it 'returns true on succesful request' do
        stub_request(:post, %r{\Ahttp://app.com*}).to_return(body: fixture_file('feature.json'))
        expect(subject.add('name')).to be true
      end

      it 'returns false on error'
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
        subject.remove('pane')
        expect(a_request(:delete, 'http://app.com/mount-point/api/v1/features/pane')).to have_been_made.once
      end

      it 'returns true on succesful request' do
        stub_request(:delete, %r{\Ahttp://app.com*})
        expect(subject.remove('pane')).to be true
      end

      it 'returns false on error'
    end

    describe '#enable' do
      context 'groups gate' do
        it 'requests correct url' do
          gate = instance_double('Gate', name: :group,
                                         key: :groups)

          feature = instance_double('Feature', key: :admin)
          thing = instance_double('Thing', value: 'admins')

          stub_request(:post, %r{\Ahttp://app.com*})
          subject.enable(feature, gate, thing)
          expect(a_request(:post, 'http://app.com/mount-point/api/v1/features/admin/groups').with(body: { name: 'admins' }.to_json)).to have_been_made.once
        end

        it 'returns true on successful requests' do
          gate = instance_double('Gate', name: :group,
                                         key: :groups)

          feature = instance_double('Feature', key: :admin)
          thing = instance_double('Thing', value: 'admins')

          stub_request(:post, %r{\Ahttp://app.com*})
          expect(subject.enable(feature, gate, thing)).to be true
        end

        it 'returns false on error'
      end

      context 'actors gate' do
        it 'requests correct url' do
          gate = instance_double('Gate', name: :actor, key: :actors)
          feature = instance_double('Feature', key: :admin)
          thing = instance_double('Thing', value: 'user:22')

          stub_request(:post, %r{\Ahttp://app.com*})
          subject.enable(feature, gate, thing)
          expect(a_request(:post, 'http://app.com/mount-point/api/v1/features/admin/actors').with(body: { flipper_id: 'user:22' }.to_json)).to have_been_made.once
        end
      end
    end

    describe '#disable' do
      it 'requests correct url' do
        gate = instance_double('Gate', name: :group, key: :groups)
        feature = instance_double('Feature', key: :admin)
        thing = instance_double('Thing', value: 'admins')
        stub_request(:delete, %r{\Ahttp://app.com*})
        subject.disable(feature, gate, thing)
        expect(a_request(:post, 'http://app.com/mount-point/api/v1/features/admin/groups'))
      end

      it 'returns true on succesful request' do
        gate = instance_double('Gate', name: :group, key: :groups)
        feature = instance_double('Feature', key: :admin)
        thing = instance_double('Thing', value: 'admins')
        stub_request(:delete, %r{\Ahttp://app.com*})
        expect(subject.disable(feature, gate, thing)).to be true
      end

      it 'returns false on error'
    end
  end

  def fixture_file(name)
    fixtures_path = File.expand_path('../../../fixtures', __FILE__)
    File.new(fixtures_path + '/' + name)
  end
end
