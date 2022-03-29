module Flipper
    module Gates
      class DeniedActor < Gate
        # Internal: The name of the gate. Used for instrumentation, etc.
        def name
          :denied_actor
        end
  
        # Internal: Name converted to value safe for adapter.
        def key
          :denied_actors
        end
  
        def data_type
          :set
        end
  
        def enabled?(value)
          !value.empty?
        end

        def deniable?
          true
        end
  
        # Internal: Checks if the gate is open for a thing.
        #
        # Returns true if gate open for thing, false if not.
        def open?(context)
          value = context.values[key]
          if context.thing.nil?
            true
          else
            if protects?(context.thing)
              actor = wrap(context.thing)
              denied_actor_ids = value
              !denied_actor_ids.include?(actor.value)
            else
              true
            end
          end
        end
  
        def wrap(thing)
          Types::DeniedActor.wrap(thing)
        end
  
        def protects?(thing)
          Types::DeniedActor.wrappable?(thing)
        end
      end
    end
  end
  