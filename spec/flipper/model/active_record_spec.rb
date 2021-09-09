require 'helper'
require 'active_record'
require 'flipper/model/active_record'

# Turn off migration logging for specs
ActiveRecord::Migration.verbose = false

RSpec.describe Flipper::Model::ActiveRecord do
  before(:all) do
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
  end

  before(:each) do
    ActiveRecord::Base.connection.execute <<-SQL
      CREATE TABLE users (
        id integer PRIMARY KEY,
        name string NOT NULL,
        age integer,
        is_confirmed boolean,
        created_at datetime NOT NULL,
        updated_at datetime NOT NULL
      )
    SQL
  end

  after(:each) do
    ActiveRecord::Base.connection.execute("DROP table IF EXISTS `users`")
  end

  class User < ActiveRecord::Base
    include Flipper::Model::ActiveRecord
  end

  describe "flipper_properties" do
    subject { User.create!(name: "Test", age: 22, is_confirmed: true) }

    it "includes all attributes" do
      expect(subject.flipper_properties).to eq({
        "type" => "User",
        "id" => subject.id,
        "name" => "Test",
        "age" => 22,
        "is_confirmed" => true,
        "created_at" => subject.created_at,
        "updated_at" => subject.updated_at
      })
    end
  end
end
