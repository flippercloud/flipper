
# Usage (from the repo root):
# env FLIPPER_CLOUD_TOKEN=<token> bundle exec ruby examples/cloud/basic.rb

require_relative "./cloud_setup"
require 'bundler/setup'
require 'flipper/cloud'

Flipper.enabled?(:audit_log)
Flipper.enabled?(:audit_log)
Flipper.enabled?(:redesign)
Flipper.enabled?(:search)
Flipper.enabled?(:search_pro)
Flipper.enabled?(:stats)
Flipper.enabled?(:subscriptions)
