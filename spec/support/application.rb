# frozen_string_literal: true

# The setup this gem runs in: a Rails application inside a Sidekiq process, with Sidekiq's Rails
# integration (reloader, ActiveJob adapter) and Apartment's railtie in place. The railtie of this gem
# installs its middleware while the application boots, as it does in an application.
require 'logger'
require 'rails'
require 'active_record/railtie'
require 'active_job/railtie'
# From here on Sidekiq.server? is true, so configure_server blocks apply as in a Sidekiq process.
require 'sidekiq/cli'
require 'apartment'
require 'apartment-sidekiq'

module TestApplication
  class Application < Rails::Application
    config.root = __dir__
    config.eager_load = false
    config.logger = Logger.new(nil)
    config.active_job.queue_adapter = :sidekiq
  end
end

Sidekiq.default_configuration.logger = Logger.new(nil)
Sidekiq.default_configuration.redis = { url: ENV.fetch('REDIS_URL') }

TestApplication::Application.initialize!
