app = Rack::Builder.new do
    use Signet::Rails::Builder do 
        provider name: :google, 
          type: :login,
          client_id:     '106644416174-sl0b09fja92d7mnnp7ibkv72e6qdkdp1.apps.googleusercontent.com',
          client_secret: 'pOf-WWuhMYe-wRRL7psP89Yr',
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

run app