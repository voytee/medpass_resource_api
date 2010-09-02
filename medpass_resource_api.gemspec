require File.expand_path('../lib/medpass_resource_api/', __FILE__)
 
Gem::Specification.new do |gem|
  gem.name = 'medpass_resource_api'
  gem.version = '0.1.9'
  gem.date = Date.today.to_s
  #gem.add_dependency('activeresource', '>=2.0.2')
  gem.homepage = 'http://github.com/voytee/medpass_resource_api'
  
  gem.summary = "Restful API for accessing medpass medical community resources"
  gem.description = "For Activeweb company purpose only"
  
  gem.authors = ['Wojciech Pasternak - voytee']
  gem.email = 'wpasternak@gmail.com'
  gem.rubyforge_project = nil
  gem.has_rdoc = false
  
  gem.files = ['init.rb', 
               'lib/medpass_resource_api.rb', 
               'lib/medpass_resource_api/medpass_user.rb', 
               'lib/medpass_resource_api/medpass_user_friend.rb', 
               'lib/medpass_resource_api/medpass_message.rb']
  gem.require_paths = ['lib']
	       

end
 
