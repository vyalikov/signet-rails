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
          @credentials.save! if @credentials.changed?
        end

        def self.generate_user_uid(id, provider_name)
          "#{provider_name}_#{id}"
        end

        # should return [USER] abstract structure 
        def self.first_or_create_user(uid, provider_name)
          User.first_or_create(uid: generate_user_uid(uid, provider_name) )
        end

        # should return [USER] abstract structure
        def self.get_user_by_id(id)
          User.find(id)
        end

        # user is [USER] abstract structure - returns [CREDENTIAL] structure
        def self.get_user_credentials(user, provider_name)
          user.o_auth2_credentials.where(name: provider_name).first # activerecord table structure
        end

        def self.get_or_initialize_user_credentials(user, provider_name)
          user.o_auth2_credentials.first_or_create(name: provider_name)
        end

      end
    end
  end
end
