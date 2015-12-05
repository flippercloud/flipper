require 'helper'

RSpec.describe Flipper::UI::Action do
  before(:each) do
    get '/', {}, headers
  end

  let(:headers) { {} }
  let(:action) { Flipper::UI::Action.new(flipper, last_request) }

  it 'should have an app breadcrumb' do
    expect(action.instance_variable_get("@breadcrumbs")).to be_an(Array)
    expect(action.instance_variable_get("@breadcrumbs").size).to eq(1)
    expect(action.instance_variable_get("@breadcrumbs").first.text).to eq('App')
  end

  context 'with the app_path set to false' do
    it 'should not have any breadcrumbs' do
      Flipper::UI.app_path = false
      expect(action.instance_variable_get("@breadcrumbs")).to be_an(Array)
      expect(action.instance_variable_get("@breadcrumbs")).to be_empty
      Flipper::UI.app_path = nil
    end
  end

  describe '#app_path' do
    it 'should default to the application root' do
      expect(action.app_path).to eq('/')
    end

    context 'with the app_path turned off' do
      it 'should be nil' do
        Flipper::UI.app_path = false
        expect(action.app_path).to be_nil
        Flipper::UI.app_path = nil
      end
    end

    context 'with the app_path specified' do
      let(:headers) { { 'HTTP_REFERER' => '/bogus' } }

      it 'should return the correct path' do
        Flipper::UI.app_path = '/admin'
        expect(action.app_path).to eq('/admin')
        Flipper::UI.app_path = nil
      end
    end

    context 'with a referer set' do
      let(:headers) { { 'HTTP_REFERER' => '/admin' } }

      it 'should return the correct path' do
        expect(action.app_path).to eq('/admin')
      end
    end
  end
end
