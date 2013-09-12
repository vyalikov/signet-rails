require 'signet/oauth_2'

module Signet
  module Rails

    class Factory

      def self.create_from_env name, env, opt_hsh = {load_token: true}
        
        # TODO: not pretty...thread safe? best approach? Other uses below
        handler = env["signet.#{name.to_s}"]
	      instance = env["signet.#{name.to_s}.instance"]
	
        #client = instance.obj
        client = instance

        return client if !!client

      	if handler.nil? 
      	  raise ArgumentError, "Unable to find signet handler named #{name.to_s}"
      	end

        client = Signet::OAuth2::Client.new handler.options

        if opt_hsh[:load_token]
          obj = handler.options[:extract_from_env].call env, client
          handler.load_token_state obj, client

          #instance.obj = obj
	        env["signet.#{name.to_s}.instance"] = obj
        end

        client
      end
    end
  end
end

