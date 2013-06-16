require 'signet/oauth_2'
require 'signet/rails'
require 'rack/utils'

module Signet
  module Rails
    class Handler
      def initialize(app, opts = {}, &block)
	@app = app
	@options = opts
      end

      def options
	@options
      end

      def handle(env)

	if "/signet/#{@options[:name]}/login" == env['PATH_INFO'] && 'GET' == env['REQUEST_METHOD']
	  client = Factory.create_from_env @options[:name], env
	  r = Rack::Response.new

	  # TODO: a better way of filtering down to the auth options
	  auth_options_whitelist = [:approval_prompt]
	  auth_options = @options.select { |k,_| auth_options_whitelist.include?(k) }
	  redirect_uri = client.authorization_uri(auth_options).to_s
	  r.redirect(redirect_uri)
	  r.finish
	elsif "/signet/#{@options[:name]}/callback" == env['PATH_INFO'] 
	  client = Factory.create_from_env @options[:name], env, load_token: false
	  query_string_params = Rack::Utils.parse_query(env['QUERY_STRING'])
	  client.code = query_string_params['code']
	  fat = client.fetch_access_token!

	  if @options[:handle_callback]
	    # try to get the token store
	    obj = @options[:extract_by_oauth_id].call client.decoded_id_token['id'], client
	    persist_token_state obj, client
	    obj.persist
	    env["signet.#{options[:name]}.obj"] = obj.obj

	  else
	    # pass this on for handling by the rails app
	    env["signet.#{options[:name]}.client"] = client

	  end
	  
	  [nil,nil,nil]
	end
      end

      def persist_token_state wrapper, client
	for i in @options[:persist]
	  if client.respond_to?(i) && wrapper.obj.respond_to?(i.to_s+'=')
	    wrapper.obj.method(i.to_s+'=').call(client.method(i).call)
	  end
	end
      end

      def load_token_state wrapper, client
	for i in @options[:persist]
	  if wrapper.obj.respond_to?(i) && client.respond_to?(i.to_s+'=')
	    client.method(i.to_s+'=').call(wrapper.obj.method(i).call)
	  end
	end
      end

      def call(env)
	# rework this to use singleton?
	env["signet.#{@options[:name]}"] = self

	status, headers, body = handle(env)
	
	unless status

	  status, headers, body = @app.call(env)

	  obj = env["signet.#{@options[:name]}.instance"] 
	  if !!obj
	    obj.persist
	  end

	end

	[status, headers, body]
      end

    end
  end
end
