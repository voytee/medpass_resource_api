module MedpassResourceApi
  class MedpassUser < ActiveResource::Base
    self.site = "#{MedpassResourceApi.configuration.medpass_url}/resource_api/"
    self.format = :json
    self.element_name = 'user'
  end
end
