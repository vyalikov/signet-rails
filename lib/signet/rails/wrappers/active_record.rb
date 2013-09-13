module Signet
  module Rails
    module Wrappers
      class ActiveRecord
        def initialize(credentials, client)
          @credentials = credentials
          @client = client
        end

        attr_reader :credentials
        attr_reader :client

        def persist
          @credentials.save if @credentials.changed?
        end
      end
    end
  end
end
