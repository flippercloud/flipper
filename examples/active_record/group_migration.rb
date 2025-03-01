# This is an example script that shows how to migrate from a bunch of individual
# actors to a group. Should be useful for those who have ended up with large
# actor sets and want to slim them down for performance reasons.

require_relative "./ar_setup"
require 'flipper/adapters/active_record'
require 'active_support/all'

# 1. enable feature for 100 actors, make 80 influencers
users = 100.times.map do |n|
  influencer = n < 80 ? true : false
  user = User.create(name: n, influencer: influencer)
  Flipper.enable :stats, user
  user
end

# check enabled, should all be because individual actors are enabled
print 'Should be [[true, 100]]: '
print users.group_by { |user| Flipper.enabled?(:stats, user) }.map { |result, users| [result, users.size]}
puts

# 2. register a group so flipper knows what to do with it
Flipper.register(:influencers) do |actor, context|
  actor.respond_to?(:influencer) && actor.influencer
end

# 3. enable group for feature, THIS IS IMPORTANT
Flipper.enable :stats, :influencers

# check enabled again, should all still be true because individual actors are
# enabled, but also the group gate would return true for 80 influencers. At this
# point, it's kind of double true but flipper just cares if any gate returns true.
print 'Should be [[true, 100]]: '
print users.group_by { |user| Flipper.enabled?(:stats, user) }.map { |result, users| [result, users.size]}
puts

# 4. now we want to clean up the actors that are covered by the group to slim down
# the actor set size. So we loop through actors and remove them if group returns
# true for the provided actor and context.
Flipper[:stats].actors_value.each do |flipper_id|
  # Hydrate the flipper_id into an active record object. Modify this based on
  # your flipper_id's if you use anything other than active record models and
  # the default flipper_id provided by flipper.
  class_name, id = flipper_id.split(';')
  klass = class_name.constantize
  user = klass.find(id)

  # if user is in group then disable for actor because they'll still get the feature
  context = Flipper::FeatureCheckContext.new(
    feature_name: :stats,
    values: Flipper[:stats].gate_values,
    actors: [Flipper::Types::Actor.wrap(user)]
  )

  if Flipper::Gates::Group.new.open?(context)
    Flipper.disable(:stats, user)
  end
end

# check enabled again, should be the same result as previous checks
print 'Should be [[true, 100]]: '
print users.group_by { |user| Flipper.enabled?(:stats, user) }.map { |result, users| [result, users.size]}
puts

puts "Actors enabled: #{Flipper[:stats].actors_value.size}"
puts "Groups enabled: #{Flipper[:stats].groups_value.size}"

puts "All actors that could be migrated to groups were migrated. Yay!"
