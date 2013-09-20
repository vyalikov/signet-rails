require 'signet/oauth_2'
require 'signet/oauth_2/client'

module Signet
  module Rails

    class Factory

      def self.create_from_env(name, env, options = { load_token: true })
        # TODO: not pretty...thread safe? best approach? Other uses below
        env["signet.#{name}.instance"] ||
        get_client_from_handler(env["signet.#{name}"], name, env, options)
      end

      private

      def self.get_client_from_handler(handler, name, env, options)
        raise ArgumentError, "Unable to find signet handler named #{name}" unless handler

        client = Signet::OAuth2::Client.new handler.options
        extract_instance_from_env(handler, env, client) if options[:load_token]

        client
      end

      def self.extract_instance_from_env(handler, env, client)
        obj = handler.options[:extract_from_session].call env['rack.session'], client
        handler.load_token_state obj, client

        # client.obj = obj
        env["signet.#{name}.instance"] = obj
      end
    end
  end
end

