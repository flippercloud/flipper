module Flipper
  module Identifier
    def flipper_id
      "#{self.class.name};#{id}"
    end
  end
end
