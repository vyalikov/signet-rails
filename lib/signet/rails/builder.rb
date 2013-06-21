require 'signet/rails'
require 'active_support/core_ext/string'

module Signet
  module Rails
    class Builder < ::Rack::Builder
      @@default_options = {}

      def self.set_default_options opts = {}
	# normalize to symbol hash
	n_opts = opts.inject({}) { |memo,(k,v)| memo[k.to_sym] = v; memo }
	@@default_options = n_opts
      end

      def initialize(app, &block)
	super
      end

      def provider(opts = {}, &block)
	# normalize to symbol hash
	n_opts = opts.inject({}) { |memo,(k,v)| memo[k.to_sym] = v; memo }

	# use the default_options as a base... then merge these changes on top
	combined_options = @@default_options.merge(n_opts)

	# now set some defaults if they aren't already set
	
	combined_options[:persist_attrs] ||= [:refresh_token, :access_token, :expires_in, :issued_at]
	combined_options[:name] ||= :google

	# TODO: see https://developers.google.com/accounts/docs/OAuth2Login#authenticationuriparameters
	combined_options[:approval_prompt] ||= 'auto'

	# unless specified, we need to set this at request-time because we need the env to get server etc
	# combined_options[:redirect_uri] = ??? need env 
	
	# TODO: better way of sourcing these defaults... from signet?
	combined_options[:authorization_uri] ||= 'https://accounts.google.com/o/oauth2/auth'
	combined_options[:token_credential_uri] ||= 'https://accounts.google.com/o/oauth2/token'

	# whether we handle the persistence of the auth callback or simply pass-through
	combined_options[:handle_auth_callback] ||= true

	# method to get the persistence object when creating a client via the factory
	combined_options[:extract_from_env] ||= lambda do |env, client|
	  u = nil
	  session = env['rack.session']
	  if !!session && !!session[:user_id]
	    begin
	      u = User.find(session[:user_id])
	    rescue ActiveRecord::RecordNotFound => e
	    end
	  end
	  u
	end

	# when on an auth_callback, how do we get the persistence object from the id?
	combined_options[:extract_by_oauth_id] ||= lambda do |id, client|
	  u = nil
	  begin
	    u = User.where(uid: id).first_or_initialize(
	      refresh_token: client.refresh_token
	    )
	  rescue ActiveRecord::RecordNotFound => e
	  end
	  u
	end

	combined_options[:persistence_wrapper] ||= :active_record
	persistence_wrapper = lambda do |meth|
	  lambda do |context, client|
	    y = meth.call context, client
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
	base_options = combined_options
	auth_options = base_options.select { |k,v| auth_option_keys.include? k }

	use Signet::Rails::Handler, base_options, auth_options, &block
      end

      def call(env)
	to_app.call(env)
      end
    end
  end
end
