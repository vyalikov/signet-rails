require 'spec_helper'
require 'open-uri'
require 'test/unit'
require 'ostruct'


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

  def test_make_google_api_client

    get '/signet/google/auth'
    follow_redirect!

    get '/signet/google/auth_callback', { code: 'abracadabra_test_code' }

    # signet = OpenStruct.new
    # signet.options = {:client_id => 101}

    # fake_env ={ user_id: 'mocked_1007007', 'signet.google' => signet}

    auth = Signet::Rails::Factory.create_from_env :google, last_request.env

  end

end