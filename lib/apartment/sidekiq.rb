# frozen_string_literal: true

require 'apartment'
require 'sidekiq'

require 'apartment/sidekiq/version'
require 'apartment/sidekiq/job_callbacks'
require 'apartment/sidekiq/middleware/client'
require 'apartment/sidekiq/middleware/server'

module Apartment
  module Sidekiq
    module Middleware
      # The railtie calls this while a Rails application boots, call it yourself without Rails.
      def self.run
        ::Sidekiq.configure_client do |config|
          config.client_middleware do |chain|
            chain.add Client
          end
        end

        ::Sidekiq.configure_server do |config|
          config.client_middleware do |chain|
            chain.add Client
          end

          # First, so that every other server middleware runs in the tenant of the job as well.
          config.server_middleware do |chain|
            chain.prepend Server
          end
        end
      end
    end
  end
end

::Sidekiq::Job::Options::ClassMethods.prepend(Apartment::Sidekiq::JobCallbacks)

require 'apartment/sidekiq/railtie' if defined?(Rails::Railtie)
