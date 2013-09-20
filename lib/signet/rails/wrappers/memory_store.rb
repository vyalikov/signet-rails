require "ostruct"

module Signet
  module Rails
    module Wrappers
      class MemoryStore

        def initialize(credentials, client)
          @credentials = credentials
          @client = client
          @@usersData = {}
        end

        def persist
          false
        end

        attr_reader :credentials
        attr_reader :client

        # should return [USER] abstract structure 
        def self.first_or_create_user(uid, provider_name)
          @@usersData ||= {}

          user_hash_name = generate_uid(uid, provider_name)
          return @@usersData[user_hash_name] if @@usersData[user_hash_name]

          user = OpenStruct.new
          user.id = uid # simulate DB
          user.uid  = generate_uid(uid, provider_name)
          user.credentials = {}

          @@usersData[user_hash_name] = user
        end

        # should return [USER] abstract structure
        def self.get_user_by_id(id)
          @@usersData[id]
        end

        # user is [USER] abstract structure - returns [CREDENTIAL] structure
        def self.get_user_credentials(user, provider_name)
          user.credentials[provider_name]
        end

        def self.get_or_initialize_user_credentials(user, provider_name)

          return user.credentials[provider_name] if user.credentials[provider_name]

          credential = OpenStruct.new
          credential.name = provider_name
          credential.signet = {}                     
          credential.id = provider_name.to_s + Random.rand(999999).to_s # simulate DB
          credential.user = user; 

          user.credentials[provider_name] = credential
        end

        ########################################################################
        def self.generate_uid(id, provider_name)
          "user_#{provider_name}_#{id}"
        end

      end
    end
  end
end
