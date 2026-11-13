# frozen_string_literal: true

module Apartment
  module Sidekiq
    module Middleware
      # Stores the tenant a job is enqueued in, unless the job names one already.
      class Client
        include ::Sidekiq::ClientMiddleware

        def call(_job_class, job, _queue, _redis_pool)
          job['apartment'] ||= Apartment::Tenant.current
          yield
        end
      end
    end
  end
end
