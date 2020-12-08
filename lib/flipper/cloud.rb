require "flipper"
require "flipper/cloud/configuration"
require "flipper/cloud/dsl"

module Flipper
  module Cloud
    # Public: Returns a new Flipper instance with an http adapter correctly
    # configured for flipper cloud.
    #
    # token - The String token for the environment from the website.
    # options - The Hash of options. See Flipper::Cloud::Configuration.
    # block - The block that configuration will be yielded to allowing you to
    #         customize this cloud instance and its adapter.
    def self.new(token, options = {})
      configuration = Configuration.new(options.merge(token: token))
      yield configuration if block_given?
      DSL.new(configuration)
    end
  end
end
