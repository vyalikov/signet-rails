require 'signet/rails'
require 'active_support/core_ext/string'

module Signet
  module Rails
    class Builder < ::Rack::Builder
      @@default_options = {}

      def self.set_default_options opts = {}
	# normalize to symbol hash
	n_opts = opts.symbolize_keys

	@@default_options = n_opts
      end

      def initialize(app, &block)
	super
      end

      def provider(opts = {}, &block)
	# normalize to symbol hash
	n_opts = opts.symbolize_keys

	# use the default_options as a base... then merge these changes on top
	combined_options = @@default_options.merge(n_opts)

	# now set some defaults if they aren't already set
	combined_options[:persist_attrs] ||= [:refresh_token, :access_token, :expires_in, :issued_at]
	combined_options[:name] ||= :google

	# is this a login-based OAuth2 adapter? If so, the callback will be used to identify a
	# user and create one if necessary
	# Options: :login, :webserver
	combined_options[:type] ||= :webserver

	# name of hash-behaving attribute on our wrapper that contains credentials
	# keyed by :name
	# {
        #   "google": {
        #     "uid": "012345676789abcde",
        #     "refresh_token": "my_first_refresh_token",
        #     "access_token": "my_first_access_token",
        #     "expires_in": 123
        #   }
        # }
	combined_options[:storage_attr] ||= :signet

	# TODO: see https://developers.google.com/accounts/docs/OAuth2Login#authenticationuriparameters
	combined_options[:approval_prompt] ||= 'auto'

	# unless specified, we need to set this at request-time because we need the env to get server etc
	# combined_options[:redirect_uri] = ??? need env 
	
	# TODO: better way of sourcing these defaults... from signet?
	combined_options[:authorization_uri] ||= 'https://accounts.google.com/o/oauth2/auth'
	combined_options[:token_credential_uri] ||= 'https://accounts.google.com/o/oauth2/token'

	# whether we handle the persistence of the auth callback or simply pass-through
	combined_options[:handle_auth_callback] ||= true

	# The following lambda will be used when creating a new client in a factory
	# to get the persistence object 
	combined_options[:extract_from_env] ||= lambda do |env, client|
	  oac = nil
	  session = env['rack.session']
	  if session && session[:user_id]
	    begin
	      u = User.find(session[:user_id])
	      oac = u.o_auth2_credentials.where(name: combined_options[:name]).first
	    rescue ActiveRecord::RecordNotFound => e
	    end
	  end
	  oac
	end

	# The following lambda will be used when handling the callback from the oauth server
	# In this flow we might not yet have established a session... need to handle two
	# flows, one for login, one not
	# when on a login auth_callback, how do we get the persistence object from the JWT?
	combined_options[:extract_by_oauth_id] ||= lambda do |env, client, id|
	  oac = nil
	  begin
	    u = nil
	    if combined_options[:type] == :login
	      u = User.first_or_create(uid: combined_options[:name].to_s + "_" + id)
	    else
	      session = env['rack.session']
	      if session && session[:user_id]
		begin
		  u = User.find(session[:user_id])
		rescue ActiveRecord::RecordNotFound => e
		end
	      else
		raise "Expected to be able to find user in session"
	      end
	    end

	    oac = u.o_auth2_credentials.first_or_initialize(name: combined_options[:name])

	  rescue ActiveRecord::RecordNotFound => e
	  end

	  oac
	end

	combined_options[:persistence_wrapper] ||= :active_record

	# define a lambda that returns a lambda that wraps our OAC lambda return object
	# in a persistance object

	persistence_wrapper = lambda do |meth|
	  lambda do |env, client, *args|
	    y = meth.call env, client, *args
	    klass_str = combined_options[:persistence_wrapper].to_s
	    require "signet/rails/wrappers/#{klass_str}"
	    w = "Signet::Rails::Wrappers::#{klass_str.camelize}".constantize.new y, client
	  end
	end

	combined_options[:extract_by_oauth_id] = persistence_wrapper.call combined_options[:extract_by_oauth_id]
	combined_options[:extract_from_env] = persistence_wrapper.call combined_options[:extract_from_env]

	# TODO: check here we have the basics?
	
	# TODO: better auth_options split?
	auth_option_keys = [:prompt, :redirect_uri, :access_type, :approval_prompt, :client_id]
	auth_options = combined_options.select { |k,v| auth_option_keys.include? k }

	use Signet::Rails::Handler, combined_options, auth_options, &block
      end

      def call(env)
	to_app.call(env)
      end
    end
  end
end
