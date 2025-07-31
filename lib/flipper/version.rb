module Flipper
  VERSION = '1.3.6'.freeze

  REQUIRED_RUBY_VERSION = '2.6'.freeze
  NEXT_REQUIRED_RUBY_VERSION = '3.0'.freeze

  REQUIRED_RAILS_VERSION = '5.2'.freeze
  NEXT_REQUIRED_RAILS_VERSION = '6.1.0'.freeze

  def self.deprecated_ruby_version?
    Gem::Version.new(RUBY_VERSION) < Gem::Version.new(NEXT_REQUIRED_RUBY_VERSION)
  end
end
