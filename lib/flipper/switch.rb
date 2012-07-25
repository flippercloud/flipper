module Flipper
  class Switch
    Key = :switch

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
