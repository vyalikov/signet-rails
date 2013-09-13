module Signet
  module Rails
    module Wrappers
      class ActiveRecord
        def initialize(obj, client)
          @obj = obj
          @client = client
        end

        attr_reader :obj
        attr_reader :client

        def persist
          @obj.save if @obj.changed?
        end
      end
    end
  end
end
