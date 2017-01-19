require 'helper'
require 'flipper/adapters/http'
require 'webmock/rspec'

RSpec.describe Flipper::Adapters::Http do
  subject { described_class.new("http://app.com/mount-point") }

  context 'request routes' do
    describe '#get' do
      it 'requests correct url' do
        stub_request(:get, %r{\Ahttp://app.com*}).to_return(body: File.new( File.expand_path('../../../fixtures', __FILE__) + "/feature.json"))
        subject.get("name")
        expect(a_request(:get, "http://app.com/mount-point/api/v1/features/name")).to have_been_made.once
      end
    end

    describe '#add' do
      it 'requests correct url' do
        stub_request(:post, %r{\Ahttp://app.com*}).to_return(body: File.new( File.expand_path('../../../fixtures', __FILE__) + "/feature.json"))
        subject.add("name")
        expect(a_request(:post, "http://app.com/mount-point/api/v1/features")).to have_been_made.once
      end
    end

    describe '#features' do
      it 'requests correct url' do
        stub_request(:get, %r{\Ahttp://app.com*})
        subject.features
        expect(a_request(:get, "http://app.com/mount-point/api/v1/features")).to have_been_made.once
      end
    end

    describe '#remove' do
      it 'requests correct url' do
        stub_request(:delete, %r{\Ahttp://app.com*})
        subject.remove("pane")
        expect(a_request(:delete, "http://app.com/mount-point/api/v1/features/pane")).to have_been_made.once
      end
    end

    describe '#enable' do
      context 'groups gate' do
        it 'requests correct url' do
          gate = instance_double("Gate", name: :group,
                                 key: :groups)
          feature = instance_double("Feature", key: :admin)
          thing = instance_double("Thing", value: "admins")

          stub_request(:post, %r{\Ahttp://app.com*})
          subject.enable(feature, gate, thing)
          expect(a_request(:post, "http://app.com/mount-point/api/v1/features/admin/groups").with(body: { name: "admins" }.to_json)).to have_been_made.once
        end
      end

      context 'actors gate' do
        it 'requests correct url' do
          gate = instance_double("Gate", name: :actor, key: :actors)
          feature = instance_double("Feature", key: :admin)
          thing = instance_double("Thing", value: "user:22")

          stub_request(:post, %r{\Ahttp://app.com*})
          subject.enable(feature, gate, thing)
          expect(a_request(:post, "http://app.com/mount-point/api/v1/features/admin/actors").with(body: { flipper_id: "user:22" }.to_json)).to have_been_made.once
        end
      end
    end

    describe '#disable' do
      it 'requests correct url' do
        gate = instance_double("Gate", name: :group, key: :groups)
        feature = instance_double("Feature", key: :admin)
        thing = instance_double("Thing", value: "admins")
        stub_request(:post, %r{\Ahttp://app.com*})
        subject.enable(feature, gate, thing)
        expect(a_request(:delete, "http://app.com/mount-point/api/v1/features/admin/groups"))
      end
    end
  end
end
