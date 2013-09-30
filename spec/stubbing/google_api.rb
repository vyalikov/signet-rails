require 'webmock'
require 'json'
require 'jwt'
require 'signet/oauth_2/client'

require 'addressable/uri'

include WebMock::API



id_token = JWT.encode({'aud' => ENV['CLIENT_ID'], 'sub' => 'testid'}, '')

# {"access_token"=>"ya29.AHES6ZTwesblW46ihyqemJuEsGrzoovgWvR67rZThhS1dUwhqnF5VrmHmA", 
#   "token_type"=>"Bearer", 
#   "expires_in"=>3599, 
#   "id_token"=> "eyJhbGciOiJSUzI1NiIsImtpZCI6IjY5ZTFlMDBhZWFmMGNmNmU5MmQ1NzBmM2M0ZDhhOTEyY2Y4ODUwZmMifQ.eyJpc3MiOiJhY2NvdW50cy5nb29nbGUuY29tIiwiY2lkIjoiMTA2NjQ0NDE2MTc0LXNsMGIwOWZqYTkyZDdtbm5wN2lia3Y3MmU2cWRrZHAxLmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwiYXpwIjoiMTA2NjQ0NDE2MTc0LXNsMGIwOWZqYTkyZDdtbm5wN2lia3Y3MmU2cWRrZHAxLmFwcHMuZ29vZ2xldXNlcmNvbnRlbnQuY29tIiwidG9rZW5faGFzaCI6IkRVMzlKdEtjd0VUOUQ2Nl9iVFZhNkEiLCJhdF9oYXNoIjoiRFUzOUp0S2N3RVQ5RDY2X2JUVmE2QSIsImVtYWlsIjoidnlhbGlrb3ZAZ21haWwuY29tIiwiaWQiOiIxMTY0ODg5MjY3MzIxMDgzNDg3NzkiLCJzdWIiOiIxMTY0ODg5MjY3MzIxMDgzNDg3NzkiLCJhdWQiOiIxMDY2NDQ0MTYxNzQtc2wwYjA5ZmphOTJkN21ubnA3aWJrdjcyZTZxZGtkcDEuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJ2ZXJpZmllZF9lbWFpbCI6InRydWUiLCJlbWFpbF92ZXJpZmllZCI6InRydWUiLCJpYXQiOjEzODAxOTY0MTAsImV4cCI6MTM4MDIwMDMxMH0.sKgrBTDPyTgUb6U-dTnRVc478gM-gdDheOxDYH8p7r62jJ3Ziz5Uow1WHU_U_oHta3zIjN2IWMQYgAedzXMrQy-4qolYMg3Nin2z81Ym-njqff3taIWcJx28GwFnZLZPJYEfblKEMXEPrJdQ5BSj7H16H94lTA7YcXvHG7HH4vc"}

stubbed_access_token = {
  token_type: "Bearer",
  expires_in: 3599,
  id_token: id_token,
 
}

# Addressable::URI.encode()
stub_request(:post, 'https://accounts.google.com/o/oauth2/token').
  to_return(:status => 200, :body => stubbed_access_token.to_json, :headers => {})

stub_request(:get, "https://www.googleapis.com/discovery/v1/apis/plus/v1/rest").
with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip', 'User-Agent'=>'Example Ruby application/1.0.0 google-api-ruby-client/0.7.0.rc2 Linux/3.8.0-31-generic
(gzip)'}).
to_return(:status => 200, :body => "{}", :headers => {})


