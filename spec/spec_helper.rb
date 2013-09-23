File.join(File.dirname(__FILE__), '..')

require 'stubbing/google_api.rb'
require 'rack_app/rack_app'
require 'rack'
require 'signet/rails/builder'


# creating thread with our oauth redirects [google api stup]
Thread.new { 
    app = Rack::Builder.new do
      use Signet::Rails::Builder do 
        provider name: :google, 
          type: :login,

          client_id: ENV['OAUTH_CLIENT_ID'],
          client_secret: ENV['OAUTH_CLIENT_SECRET'],
          persistence_wrapper: :memory_store,
          scope: [
          'https://www.googleapis.com/auth/userinfo.email',
          'https://www.googleapis.com/auth/userinfo.profile', 
          'https://www.googleapis.com/auth/calendar.readonly'
        ]
      end
      map "/" do
        run lambda { |env| [200, { "Content-Type" => "text/plain" }, ["OK"]] }
      end
    end


    Rack::Handler::WEBrick.run(
      app,
      :Port => 9000
    )
  }

