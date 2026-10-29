require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module BillettoAssessment
  class Application < Rails::Application
    config.load_defaults 7.1
    config.eager_load_paths << Rails.root.join("app/integrations")

    config.autoload_lib(ignore: %w(assets tasks))

  end
end
