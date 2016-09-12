require 'helper'

RSpec.describe Flipper::UI::Action do
  let(:action_subclass) {
    Class.new(described_class) do
      def noooope
        raise "should never run this"
      end

      def get
        [200, {}, "get"]
      end

      def post
        [200, {}, "post"]
      end

      def put
        [200, {}, "put"]
      end

      def delete
        [200, {}, "delete"]
      end
    end
  }

  it "won't run method that isn't whitelisted" do
    fake_request = Struct.new(:request_method, :env, :session).new("NOOOOPE", {}, {})
    action = action_subclass.new(flipper, fake_request)
    expect {
      action.run
    }.to raise_error(Flipper::UI::RequestMethodNotSupported)
  end

  it "will run get" do
    fake_request = Struct.new(:request_method, :env, :session).new("GET", {}, {})
    action = action_subclass.new(flipper, fake_request)
    expect(action.run).to eq([200, {}, "get"])
  end

  it "will run post" do
    fake_request = Struct.new(:request_method, :env, :session).new("POST", {}, {})
    action = action_subclass.new(flipper, fake_request)
    expect(action.run).to eq([200, {}, "post"])
  end

  it "will run put" do
    fake_request = Struct.new(:request_method, :env, :session).new("PUT", {}, {})
    action = action_subclass.new(flipper, fake_request)
    expect(action.run).to eq([200, {}, "put"])
  end

  it "will run delete" do
    fake_request = Struct.new(:request_method, :env, :session).new("DELETE", {}, {})
    action = action_subclass.new(flipper, fake_request)
    expect(action.run).to eq([200, {}, "delete"])
  end
end
