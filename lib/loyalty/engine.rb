require 'slim'
require 'cocoon'
require 'spreadsheet'
require 'authlogic'

module Loyalty
  class Engine < ::Rails::Engine
    isolate_namespace Loyalty
    config.generators do |g|
      g.test_framework :rspec, fixtures: false
      g.fixture_replacement :factory_girl, dir: 'spec/factories'
      g.assets false
      g.helper false
      g.template_engine :slim
    end

    initializer 'loyalty.settings' do
      Settings.add_source!(
        Loyalty::Engine.root.join('config', 'settings.yml').to_s
      )
      Settings.reload!
    end

    initializer 'loyalty.locale' do |parent|
      parent.config.i18n.load_path += Dir[root.join('config/locales/*.yml')]
    end
  end
end
