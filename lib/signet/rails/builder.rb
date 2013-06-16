require 'signet/rails'
require 'signet/rails/wrappers/active_record'

module Signet
  module Rails
    class Builder < ::Rack::Builder
      @@default_options = {}

      def self.set_default_options opts = {}
	# normalize to symbol version
	n_opts = opts.inject({}) { |memo,(k,v)| memo[k.to_sym] = v; memo }
	@@default_options = n_opts
      end

      def initialize(app, &block)
	super
      end

      def provider(opts = {}, &block)
	# normalize to symbol version
	n_opts = opts.inject({}) { |memo,(k,v)| memo[k.to_sym] = v; memo }
	combined_options = @@default_options.merge(n_opts)

	# now set some defaults if they aren't already set
	combined_options[:persist] ||= [:refresh_token, :access_token, :expires_in, :issued_at]
	combined_options[:name] ||= :google
	combined_options[:approval_prompt] ||= 'auto'
	combined_options[:redirect_uri] = "http://localhost:3000/signet/#{combined_options[:name]}/callback"
	combined_options[:authorization_uri] = 'https://accounts.google.com/o/oauth2/auth'
	combined_options[:token_credential_uri] = 'https://accounts.google.com/o/oauth2/token'
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
	combined_options[:handle_callback] ||= true
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

	def active_record_wrapper meth
	  lambda do |context, client|
	    y = meth.call context, client
	    w = Signet::Rails::Wrappers::ActiveRecord.new y, client
	  end
	end

	combined_options[:extract_by_oauth_id] = active_record_wrapper combined_options[:extract_by_oauth_id]
	combined_options[:extract_from_env] = active_record_wrapper combined_options[:extract_from_env]

	# TODO: check here we have the basics?

	use Signet::Rails::Handler, combined_options, &block
      end

      def call(env)
	to_app.call(env)
      end
    end
  end
end
