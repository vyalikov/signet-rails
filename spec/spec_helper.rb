ENV['RACK_ENV'] = 'test'
ENV['RAILS_ENV'] = 'test'

ENV['CLIENT_ID'] = '106644416174-sl0b09fja92d7mnnp7ibkv72e6qdkdp1.apps.googleusercontent.com'

require 'stubbing/google_api.rb'
require 'rack_app/rack_app'
require 'rack'
require 'signet/rails/builder'
require 'rspec'
require 'rack/test'


# WebMock.disable_net_connect!

# stub_request(:any,'https://accounts.google.com/o/oauth2/auth').to_return(:body => 'mybody')


File.join(File.dirname(__FILE__), '..')

RSpec.configure do |config|
  # Use color in STDOUT
  config.color_enabled = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate

  # config.include Rack::Test::Methods
end

# @application = nil
# # creating thread with our oauth redirects [google api stup]
# Thread.new { 
#     app = Rack::Builder.new do
#       use Signet::Rails::Builder do 
#         provider name: :google, 
#           type: :login,
#           client_id: ENV['OAUTH_CLIENT_ID'],
#           client_secret: ENV['OAUTH_CLIENT_SECRET'],
#           persistence_wrapper: :memory_store,
#           scope: [
#           'https://www.googleapis.com/auth/userinfo.email',
#           'https://www.googleapis.com/auth/userinfo.profile', 
#           'https://www.googleapis.com/auth/calendar.readonly'
#         ]
#       end
#       map "/" do
#         run lambda { |env| [200, { "Content-Type" => "text/plain" }, ["OK"]] }
#       end
#     end


#     Rack::Handler::WEBrick.run(
#       app,
#       :Port => 9000
#     )
#   }

