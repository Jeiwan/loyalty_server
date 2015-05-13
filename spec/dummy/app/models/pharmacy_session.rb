class PharmacySession < Authlogic::Session::Base
  single_access_allowed_request_types ["application/json"]
end
