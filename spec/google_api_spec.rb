require 'spec_helper'
require 'open-uri'
require 'test/unit'
require 'ostruct'

require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'


OUTER_APP = Rack::Builder.parse_file("config.ru").first

class GoogleApiSpec < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    OUTER_APP
  end

  def test_root
    get '/'
    assert last_response.ok?
  end

  def test_go_to_auth_path
    get '/signet/google/auth'
    follow_redirect!
  end

  def test_get_signet_google_auth_client

    get '/signet/google/auth'
    follow_redirect!

    get '/signet/google/auth_callback', { code: 'abracadabra_test_code' }

    insert_user_id_in_session :google, last_request.env

    auth = Signet::Rails::Factory.create_from_env :google, last_request.env

    auth
  end


  def test_google_api_client_initialization

    auth = test_get_signet_google_auth_client

    client = Google::APIClient.new(
      :application_name => 'Example Ruby application',
      :application_version => '1.0.0'
    )

    plus = client.discovered_api('plus')

    # Load client secrets from your client_secrets.json.
    client_secrets = Google::APIClient::ClientSecrets.load

    client.authorization = auth

    # Make an API call.
    result = client.execute(
      :api_method => plus.activities.list,
      :parameters => {'collection' => 'public', 'userId' => 'me'}
    )

    p result.data
  end


  private 
  def insert_user_id_in_session(provider_name, request_env)

    return if !request_env["signet.google.persistence_obj"].user
    return if !request_env["signet.google.persistence_obj"].user.uid

    if(!request_env['rack.session'])
      request_env['rack.session'] = { user_id: request_env["signet.#{provider_name}.persistence_obj"].user.uid}
    end

  end

end