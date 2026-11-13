# frozen_string_literal: true

module Apartment
  module Sidekiq
    # Sidekiq calls the sidekiq_retry_in and sidekiq_retries_exhausted blocks of a job from its retry
    # handler, which wraps the server middleware: by then the middleware has left the tenant of the
    # job again. Prepended to Sidekiq::Job::Options::ClassMethods, which ActiveJob jobs get as well,
    # so that each block switches to the tenant of the job it is called for, whoever calls it.
    # Blocks registered before this file was loaded stay as they are.
    module JobCallbacks
      def sidekiq_retry_in(&block)
        super(&JobCallbacks.in_tenant_of_job(block, job_position: 2))
      end

      def sidekiq_retries_exhausted(&block)
        super(&JobCallbacks.in_tenant_of_job(block, job_position: 0))
      end

      # A job without a tenant ran in the default tenant, so do its callbacks. Switching to a tenant
      # that no longer exists raises before the block runs, Sidekiq reports that like any error of the
      # block and goes on with the job.
      def self.in_tenant_of_job(block, job_position:)
        return if block.nil?

        lambda do |*arguments|
          job = arguments[job_position]
          Apartment::Tenant.switch(job && job['apartment']) { block.call(*arguments) }
        end
      end
    end
  end
end
