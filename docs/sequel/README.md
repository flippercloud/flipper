# Flipper Sequel

A [Sequel](https://github.com/jeremyevans/sequel) adapter for [Flipper](https://github.com/jnunemaker/flipper).

## Installation

Add this line to your application's Gemfile:

    gem 'flipper-sequel'

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install flipper-sequel

## Usage

For your convenience, a sequel migration is provided to create the necessary tables. This migration will create two database tables - flipper_features and flipper_gates.

```ruby
require 'generators/flipper/templates/sequel_migration'
CreateFlipperTablesSequel.new(Sequel::Model.db).up
```

Once you have created and executed the migration, you can use the sequel adapter by simply requiring it:

```ruby
require 'flipper-sequel`
```

**If you need to customize the adapter**, you can add this to an initializer:

```ruby
Flipper.configure do |config|
  config.adapter do
    Flipper::Adapters::Sequel.new
  end
end
```

## Internals

Each feature is stored as a row in a features table. Each gate is stored as a row in a gates table, related to the feature by the feature's key.

```ruby
require 'flipper/adapters/sequel'
adapter = Flipper::Adapters::Sequel.new
flipper = Flipper.new(adapter)

# Register a few groups.
Flipper.register(:admins) { |thing| thing.admin? }
Flipper.register(:early_access) { |thing| thing.early_access? }

# Create a user class that has flipper_id instance method.
User = Struct.new(:flipper_id)

flipper[:stats].enable
flipper[:stats].enable_group :admins
flipper[:stats].enable_group :early_access
flipper[:stats].enable_actor User.new('25')
flipper[:stats].enable_actor User.new('90')
flipper[:stats].enable_actor User.new('180')
flipper[:stats].enable_percentage_of_time 15
flipper[:stats].enable_percentage_of_actors 45

flipper[:search].enable

puts 'all rows in features table'
pp Flipper::Adapters::Sequel::Feature.all
#[#<Flipper::Adapters::Sequel::Feature @values={:key=>"stats", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
# #<Flipper::Adapters::Sequel::Feature @values={:key=>"search", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>]
puts

puts 'all rows in gates table'
pp Flipper::Adapters::Sequel::Gate.all
# [#<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"stats", :key=>"boolean", :value=>"true", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
#  #<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"stats", :key=>"groups", :value=>"admins", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
#  #<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"stats", :key=>"groups", :value=>"early_access", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
#  #<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"stats", :key=>"actors", :value=>"25", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
#  #<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"stats", :key=>"actors", :value=>"90", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
#  #<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"stats", :key=>"actors", :value=>"180", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
#  #<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"stats", :key=>"percentage_of_time", :value=>"15", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
#  #<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"stats", :key=>"percentage_of_actors", :value=>"45", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>,
#  #<Flipper::Adapters::Sequel::Gate @values={:feature_key=>"search", :key=>"boolean", :value=>"true", :created_at=>2016-11-19 13:57:48 -0500, :updated_at=>2016-11-19 13:57:48 -0500}>]
puts

puts 'flipper get of feature'
pp adapter.get(flipper[:stats])
# {:boolean=>"true",
#  :groups=>#<Set: {"admins", "early_access"}>,
#  :actors=>#<Set: {"180", "25", "90"}>,
#  :percentage_of_actors=>"45",
#  :percentage_of_time=>"15"}
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
