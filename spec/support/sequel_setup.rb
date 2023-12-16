# Setup sequel for sequel adapter and model specs. We don't want this to happen
# multiple times or it causes failures. So it lives here.
require "sequel"
Sequel::Model.db = Sequel.sqlite(':memory:')
Sequel.extension :migration, :core_extensions
