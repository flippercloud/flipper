module Flipper
  class Boolean
    Key = :boolean

    def key
      Key
    end

    def value
      true
    end

    def type
      :value
    end
  end
end
