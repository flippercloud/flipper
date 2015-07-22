require File.expand_path('../example_setup', __FILE__)

require 'flipper'
require 'flipper/adapters/memory'

adapter = Flipper::Adapters::Memory.new
flipper = Flipper.new(adapter)
stats = flipper[:stats]

# Register group
Flipper.register(:enabled_team_member) do |actor, context|
  combos = context.values[:actors].map { |flipper_id| flipper_id.split(":", 2) }
  team_names = combos.select { |class_name, id| class_name == "Team" }.map { |class_name, id| id }
  teams = team_names.map { |name| Team.find(name) }
  teams.any? { |team| team.member?(actor) }
end

# Some class that represents actor that will be trying to do something
class User
  attr_reader :id

  def initialize(id)
    @id = id
  end

  # Must respond to flipper_id
  alias_method :flipper_id, :id
end

class Team
  attr_reader :name

  def self.all
    @all ||= {}
  end

  def self.find(name)
    all.fetch(name.to_s)
  end

  def initialize(name, members)
    @name = name.to_s
    @members = members
    self.class.all[@name] = self
  end

  def id
    @name
  end

  def member?(actor)
    @members.map(&:id).include?(actor.id)
  end

  def flipper_id
    "Team:#{@name}"
  end
end

jnunemaker = User.new("jnunemaker")
jbarnette = User.new("jbarnette")
aroben = User.new("aroben")

core_app = Team.new(:core_app, [jbarnette, jnunemaker])
feature_flags = Team.new(:feature_flags, [aroben, jnunemaker])

stats.enable_actor jbarnette

do_enabled_checks = ->(*actors) {
  actors.each do |actor|
    if stats.enabled?(actor)
      puts "stats are enabled for #{actor.id}"
    else
      puts "stats are NOT enabled for #{actor.id}"
    end
  end
}

do_enabled_checks.call(jbarnette, jnunemaker, aroben)

puts "enabling team_actor group"
stats.enable_actor core_app
stats.enable_group :enabled_team_member

do_enabled_checks.call(jbarnette, jnunemaker, aroben)
