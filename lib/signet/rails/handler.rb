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

      def auth_options env
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
        status = headers = body = nil

        # TODO: better way than a gross if elsif block?
        if "/signet/#{options[:name]}/auth" == env['PATH_INFO'] && 'GET' == env['REQUEST_METHOD']

          # we are looking to auth... so nothing to load
          client = Factory.create_from_env options[:name], env, load_token: false

          r = Rack::Response.new
          redirect_uri = client.authorization_uri(auth_options(env)).to_s
          r.redirect(redirect_uri)
          status, headers, body = r.finish
        elsif "/signet/#{options[:name]}/auth_callback" == env['PATH_INFO'] && 'GET' == env['REQUEST_METHOD']
          client = Factory.create_from_env options[:name], env, load_token: false
          query_string_params = Rack::Utils.parse_query(env['QUERY_STRING'])
          client.code = query_string_params['code']
          client.redirect_uri = auth_options(env)[:redirect_uri]
          client.fetch_access_token! 

          if options[:handle_auth_callback]
            obj = options[:extract_by_oauth_id].call env, client, client.decoded_id_token['sub']
            persist_token_state obj, client
            obj.persist
            env["signet.#{options[:name]}.persistence_obj"] = obj.obj
          else
            env["signet.#{options[:name]}.auth_client"] = client
          end
        end

        [status, headers, body]
      end

      def persist_token_state wrapper, client

        if not wrapper.obj.respond_to?(options[:storage_attr])
          raise "Persistence object does not support the storage attribute #{options[:storage_attr]}"
        end

        if (store_hash = wrapper.obj.method(options[:storage_attr]).call).nil?
          store_hash = wrapper.obj.method("#{options[:storage_attr]}=").call({})
        end

        # not nice... the wrapper.obj.changed? will only be triggered if we clone the hash
        # Is this a bug? https://github.com/rails/rails/issues/11968
        # TODO: check if there is a better solution
        store_hash = store_hash.clone

        for i in options[:persist_attrs]
          if client.respond_to?(i) 
            # only transfer the value if it is non-nil
            store_hash[i.to_s] = client.method(i).call unless client.method(i).call.nil?
          end
        end

        wrapper.obj.method("#{options[:storage_attr]}=").call(store_hash)
      end

      def load_token_state wrapper, client
        if not wrapper.obj.respond_to?(options[:storage_attr])
          raise "Persistence object does not support the storage attribute #{options[:storage_attr]}"
        end

        if not (store_hash = wrapper.obj.method(options[:storage_attr]).call).nil?
          for i in options[:persist_attrs]
            if client.respond_to?(i.to_s+'=')
              client.method(i.to_s+'=').call(store_hash[i.to_s])
            end
          end
        end
      end

      def call(env)
        # rework this to use singleton?
        env["signet.#{options[:name]}"] = self

        status, headers, body = handle(env)

        unless status

          status, headers, body = @app.call(env)

          instance = env["signet.#{options[:name]}.instance"] 
          if !!instance
            persist_token_state instance, instance.client
            instance.persist
          end

        end

       [status, headers, body]
      end
    end
  end
end
