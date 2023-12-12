module Flipper
  VERSION = '1.1.2'.freeze

  REQUIRED_RUBY_VERSION = '2.6'.freeze

  NEXT_REQUIRED_RUBY_VERSION = '3.0'.freeze

  def self.deprecated_ruby_version?
    Gem::Version.new(RUBY_VERSION) < Gem::Version.new(NEXT_REQUIRED_RUBY_VERSION)
  end
end
