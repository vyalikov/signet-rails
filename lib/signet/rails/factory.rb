require 'signet/oauth_2'

module Signet
  module Rails

    class Factory
      def self.create_from_env name, env, opt_hsh = {load_token: true}
	# rework this to use singleton?
	handler = env["signet.#{name.to_s}"]

	client = Signet::OAuth2::Client.new handler.options

	if opt_hsh[:load_token]
	  obj = handler.options[:extract_from_env].call env, client
	  handler.load_token_state obj, client

	  env["signet.#{name.to_s}.instance"] = obj
	end

	client
      end
    end
  end
end

