require 'signet/oauth_2'
require 'signet/rails'
require 'rack/utils'

module Signet
  module Rails
    class Handler
      def initialize(app, opts = {}, auth_opts = {}, &block)
        @app = app
        @options = opts
        @auth_options = auth_opts
      end

      def options
        # TODO: this is because signet doesn't dup what we pass in....
        @options.dup
      end

      def auth_options(env)
        # TODO: this is because signet doesn't dup what we pass in....
        ret = @auth_options.dup
        unless ret.include? :redirect_uri
          req = Rack::Request.new env
          scheme = req.ssl? ? 'https' : 'http'
          ret[:redirect_uri] = "#{scheme}://#{req.host_with_port}/signet/#{options[:name]}/auth_callback"
        end
        ret
      end

      def handle(env)
        # set these to 'handle' the request
        status, headers, body = nil, nil, nil

        # TODO: better way than a gross if elsif block?
        if getting_auth_path?(env)
          status, headers, body = create_response env
        elsif getting_auth_callback_path?(env)
          create_and_save_auth_client_to_env env
        end

        [status, headers, body]
      end

      def persist_token_state(wrapper, client)
        storage = options[:storage_attr]
        unless wrapper.credentials.respond_to?(storage)
          fail "Persistence object does not support the storage attribute #{storage}"
        end

        store_hash = wrapper.credentials.method(storage).call ||
                      wrapper.credentials.method("#{storage}=").call({})

        # not nice... the wrapper.obj.changed? will only be triggered if we clone the hash
        # Is this a bug? https://github.com/rails/rails/issues/11968
        # TODO: check if there is a better solution
        store_hash = store_hash.clone

        store_attributes(store_hash, client)

        wrapper.credentials.method("#{storage}=").call(store_hash)
      end

      def load_token_state(wrapper, client)
        storage = options[:storage_attr]
        unless wrapper.credentials.respond_to?(storage)
          fail "Persistence object does not support the storage attribute #{storage}"
        end

        store_hash = wrapper.credentials.method(storage).call
        if store_hash
          options[:persist_attrs].each do |attribute|
            client.method("#{attribute}=").call(store_hash[attribute]) if client.respond_to?("#{attribute}=")
          end
        end
      end

      def call(env)
        # rework this to use singleton?
        env["signet.#{options[:name]}"] = self

        status, headers, body = handle(env)

        unless status
          status, headers, body = @app.call(env)
          persist_instance env
        end

       [status, headers, body]
      end

      private

      def create_response(env)
        # we are looking to auth... so nothing to load
        client = Factory.create_from_env(options[:name], env, load_token: false)

        response = Rack::Response.new
        redirect_uri = client.authorization_uri(auth_options(env)).to_s
        response.redirect(redirect_uri)

        response.finish
      end

      def create_and_save_auth_client_to_env(env)
        client = Factory.create_from_env options[:name], env, load_token: false
          query_string_params = Rack::Utils.parse_query(env['QUERY_STRING'])
          client.code = query_string_params['code']
          client.redirect_uri = auth_options(env)[:redirect_uri]

          client.fetch_access_token!

          save_env_client_and_persistence(env, client)
      end

      def save_env_client_and_persistence(env, client)
        if options[:handle_auth_callback]
          user_oauth_credentials = options[:extract_by_oauth_id].call env, client, client.decoded_id_token['sub']
          persist_token_state user_oauth_credentials, client
          user_oauth_credentials.persist
          env["signet.#{options[:name]}.persistence_obj"] = user_oauth_credentials.credentials
        else
          env["signet.#{options[:name]}.auth_client"] = client
        end
      end

      def persist_instance(env)
        instance = env["signet.#{options[:name]}.instance"]
        if instance
          persist_token_state instance, instance.client
          instance.persist
        end
      end

      def store_nonempty_attribute(store_hash, client, attribute)
        if client.respond_to?(attribute) && client.method(attribute).call
          # only transfer the value if it is non-nil
          store_hash[attribute.to_s] = client.method(attribute).call
        end
      end

      def store_attributes(store_hash, client)
        options[:persist_attrs].each do |attribute|
          store_nonempty_attribute(store_hash, client, attribute)
        end
      end

      def getting_auth_path?(env)
        "/signet/#{options[:name]}/auth" == env['PATH_INFO'] && 'GET' == env['REQUEST_METHOD']
      end

      def getting_auth_callback_path?(env)
        "/signet/#{options[:name]}/auth_callback" == env['PATH_INFO'] && 'GET' == env['REQUEST_METHOD']
      end
    end
  end
end
