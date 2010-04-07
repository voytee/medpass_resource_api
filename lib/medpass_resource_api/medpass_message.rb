module MedpassResourceApi
  class MedpassMessage < ActiveResource::Base
    self.site = "#{MedpassResourceApi.configuration.medpass_url}/resource_api/users/:user_id"
    self.format = :json
    self.element_name = 'message'
  end
end
