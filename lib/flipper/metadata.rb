require_relative './version'

module Flipper
  METADATA = {
    "documentation_uri" => "https://www.flippercloud.io/docs",
    "homepage_uri"      => "https://www.flippercloud.io",
    "source_code_uri"   => "https://github.com/flippercloud/flipper",
    "bug_tracker_uri"   => "https://github.com/flippercloud/flipper/issues",
    "changelog_uri"     => "https://github.com/flippercloud/flipper/releases/tag/v#{Flipper::VERSION}",
    "funding_uri"       => "https://github.com/sponsors/flippercloud",
  }.freeze
end
