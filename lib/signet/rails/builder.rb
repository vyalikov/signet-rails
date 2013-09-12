require 'signet/rails'
require 'active_support/core_ext/string'

module Signet
  module Rails
    class Builder < ::Rack::Builder

      class << self
        attr_accessor :default_options # better than @@ variable
      end
      Builder.default_options = {}

      BUILTIN_OPTIONS = {
        persist_attrs: [:refresh_token, :access_token, :expires_in, :issued_at],
        name: :google,

        # is this a login-based OAuth2 adapter? If so, the callback will be used to identify a
        # user and create one if necessary
        # Options: :login, :webserver
        type: :webserver,
        storage_attr: :signet,

        # TODO: see https://developers.google.com/accounts/docs/OAuth2Login#authenticationuriparameters
        approval_prompt: 'auto',
        authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
        token_credential_uri: 'https://accounts.google.com/o/oauth2/token',

        # whether we handle the persistence of the auth callback or simply pass-through
        handle_auth_callback: true,
        persistence_wrapper: :active_record
      }

      def self.set_default_options(opts = {})
        # normalize to symbol hash
        Builder.default_options = opts.symbolize_keys
      end

      def initialize(app, &block)
        super
      end

      def provider(opts = {}, &block)
        # Use BUILTIN_OPTIONS as base then merge default_options upon them, then options from parameter on top
        combined_options = BUILTIN_OPTIONS.merge(Builder.default_options.merge(opts.symbolize_keys))

        # {
        #   "google": {
        #     "uid": "012345676789abcde",
        #     "refresh_token": "my_first_refresh_token",
        #     "access_token": "my_first_access_token",
        #     "expires_in": 123
        #   }
        # }

        # unless specified, we need to set this at request-time because we need the env to get server etc
        # combined_options[:redirect_uri] = ??? need env

        # The following lambda will be used when creating a new client in a factory
        # to get the persistence object
        combined_options[:extract_from_env] ||= user_oauth_credentials_fetcher(combined_options[:name])

        # The following lambda will be used when handling the callback from the oauth server
        # In this flow we might not yet have established a session... need to handle two
        # flows, one for login, one not
        # when on a login auth_callback, how do we get the persistence object from the JWT?
        combined_options[:extract_by_oauth_id] ||= \
          user_oauth_credentials_creator(combined_options[:name], combined_options[:type])

        wrap_extraction_callbacks_in_persistence(combined_options)

        # TODO: check here we have the basics?

        # TODO: better auth_options split?
        auth_option_keys = [:prompt, :redirect_uri, :access_type, :approval_prompt, :client_id]
        auth_options = combined_options.slice(*auth_option_keys)

        use Signet::Rails::Handler, combined_options, auth_options, &block
      end

      def call(env)
        to_app.call(env)
      end

      private

      def get_or_create_user(name, id, env, creation_flag)
        if creation_flag
          User.first_or_create(uid: "#{name}_#{id}")
        else
          process_with_user_id(env, true) do |user_id|
            User.find(user_id)
          end
        end
      end

      def user_oauth_credentials_creator(name, type)
        lambda do |env, client, id|
          begin
            u = get_or_create_user(name, id, env, type == :login)
            u.o_auth2_credentials.first_or_initialize(name: name)
          rescue ActiveRecord::RecordNotFound
            nil
          end
        end
      end

      def user_oauth_credentials_fetcher(name)
        lambda do |env, client|
          process_with_user_id(env) do |user_id|
            u = User.find(user_id)
            u.o_auth2_credentials.where(name: name).first
          end
        end
      end

      def wrap_extraction_callbacks_in_persistence(combined_options)
        klass_name = combined_options[:persistence_wrapper].to_s

        combined_options[:extract_by_oauth_id] = \
          persistence_wrapper_lambda(klass_name).call combined_options[:extract_by_oauth_id]
        combined_options[:extract_from_env] = \
          persistence_wrapper_lambda(klass_name).call combined_options[:extract_from_env]
      end

      def persistence_wrapper_lambda(klass_str)
        lambda do |meth|
          lambda do |env, client, *args|
            y = meth.call env, client, *args
            require "signet/rails/wrappers/#{klass_str}"
            "Signet::Rails::Wrappers::#{klass_str.camelize}".constantize.new y, client
          end
        end
      end

      def process_with_user_id(env, session_required = false, &block)
        session = env['rack.session']

        return nil_or_fail(session_required) unless session && session[:user_id]

        begin
          yield(session[:user_id])
        rescue ActiveRecord::RecordNotFound
          nil
        end
      end

      def nil_or_fail(fail_flag)
        fail 'Expected to be able to find user in session' if fail_flag
        nil
      end

    end
  end
end
