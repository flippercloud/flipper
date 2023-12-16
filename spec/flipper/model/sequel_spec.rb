require 'flipper/model/sequel'

RSpec.describe Flipper::Model::Sequel do
  before(:each) do
    Sequel::Model.db.run <<-SQL
      CREATE TABLE users (
        id integer PRIMARY KEY,
        name string NOT NULL,
        age integer,
        is_confirmed boolean,
        created_at datetime NOT NULL,
        updated_at datetime NOT NULL
      )
    SQL

    @User = Class.new(::Sequel::Model(:users)) do
      include Flipper::Model::Sequel
      plugin :timestamps, update_on_create: true


      def self.name
        'User'
      end
    end
  end

  after(:each) do
    Sequel::Model.db.run("DROP table IF EXISTS `users`")
  end

  describe "flipper_properties" do
    subject { @User.create(name: "Test", age: 22, is_confirmed: true) }

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
