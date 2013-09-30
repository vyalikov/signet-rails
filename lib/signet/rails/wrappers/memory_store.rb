require 'ostruct'

module Signet
  module Rails
    module Wrappers
      class MemoryStore

        class << self
          attr_accessor :user_data
        end

        MemoryStore.user_data = {}

        def initialize(credentials, client)
          @credentials = credentials
          @client = client
        end

        def persist
        end

        attr_reader :credentials
        attr_reader :client


        def self.save!(user)
          MemoryStore.user_data[user.uid] = Marshal.dump user
          user
        end

        def self.load(uid)
          stored_string = MemoryStore.user_data[uid]
          return Marshal.load stored_string if stored_string
          nil
        end

        # should return [USER] abstract structure
        def self.first_or_create_user(uid, provider_name)

          user_hash_name = generate_uid(uid, provider_name)
          user = load user_hash_name
          return user if user

          user = OpenStruct.new
          user.id = uid # simulate DB
          user.uid  = generate_uid(uid, provider_name)
          user.credentials = {}


          save! user
        end

        # should return [USER] abstract structure
        def self.get_user_by_id(id)
          load id
        end

        # user is [USER] abstract structure - returns [CREDENTIAL] structure
        def self.get_user_credentials(user, provider_name)
          user.credentials[provider_name]
        end

        def self.get_or_initialize_user_credentials(user, provider_name)

          return user.credentials[provider_name] if user.credentials[provider_name]

          credential = OpenStruct.new
          credential.name = provider_name
          credential.signet = { }
          credential.id = provider_name.to_s + Random.rand(999_999).to_s # simulate DB
          credential.user = user

          user.credentials[provider_name] = credential

          save! user

          credential
        end

        ########################################################################
        def self.generate_uid(id, provider_name)
          "user_#{provider_name}_#{id}"
        end

      end
    end
  end
end
