app = Rack::Builder.new do
    use Signet::Rails::Builder do 
        provider name: :google, 
          type: :login,
          client_id:     'myclientidhere',
          client_secret: 'myclientsecrethere',
          persistence_wrapper: :memory_store,
          handle_auth_callback: true,
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

run app