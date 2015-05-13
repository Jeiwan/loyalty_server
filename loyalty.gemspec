$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'loyalty/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'loyalty'
  s.version     = Loyalty::VERSION
  s.authors     = ['Ivan Kuznetsov']
  s.email       = ['me@jeiwan.ru']
  s.description = 'Rails Engine that provides API and web-interface to work with loyalty programs'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['spec/**/*']

  s.add_dependency 'actverecord-import', '0.7.0'
  s.add_dependency 'rails', '~> 4.0'
  s.add_dependency 'slim'
  s.add_dependency 'responders', '~>2.0'
  s.add_dependency 'bootstrap-rails-engine'
  s.add_dependency 'coffee-rails'
  s.add_dependency 'kaminari'
  s.add_dependency 'cocoon'
  s.add_dependency 'rails_config'
  s.add_dependency 'spreadsheet'
  s.add_dependency 'select2-rails'
  s.add_dependency 'sidekiq'
  s.add_dependency 'authlogic', '~> 3.4.0'
  s.add_dependency 'simple_form'
  s.add_dependency 'flexible_accessibility', '~> 0.2.99.pre'

  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'timecop'
end
