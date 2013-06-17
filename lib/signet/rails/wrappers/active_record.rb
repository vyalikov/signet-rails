module Signet
  module Rails
    module Wrappers
      class ActiveRecord
        def initialize obj, client
          @obj = obj
          @client = client
        end

        def obj
          @obj
        end

        def persist
          if @obj.changed?
            @obj.save
          end
        end
      end
    end
  end
end
