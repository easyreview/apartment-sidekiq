# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require_relative 'support/application'
require_relative 'support/tenant_observations'
require_relative 'support/jobs'
require_relative 'support/sidekiq_processing'

TENANTS = %w[tenant_a tenant_b].freeze
MISSING_TENANT = 'missing_tenant'

Sidekiq.default_configuration.error_handlers << proc { |exception, context|
  SidekiqProcessing::ReportedErrors.record(exception, context)
}

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand(config.seed)

  config.include SidekiqProcessing

  config.before(:suite) do
    ActiveRecord::Base.with_connection do |connection|
      TENANTS.each { |tenant| connection.execute(%(CREATE SCHEMA IF NOT EXISTS "#{tenant}")) }
      connection.execute(%(DROP SCHEMA IF EXISTS "#{MISSING_TENANT}" CASCADE))
    end
  end

  config.before do
    Apartment::Tenant.reset
    Sidekiq.redis { |connection| connection.call('FLUSHDB') }
    TenantObservations.clear
    SidekiqProcessing::ReportedErrors.all.clear
  end
end
