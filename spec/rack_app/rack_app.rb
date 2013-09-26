class RackApp
  def call(env)

    if(env['REQUEST_PATH']=='signet/google/auth_callback')

    end
    
    return [
      200,
      {'Content-Type' => 'text/html'},
      ["Hello world!"]
    ]
  end
end