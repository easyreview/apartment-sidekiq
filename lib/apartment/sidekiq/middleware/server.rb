# frozen_string_literal: true

module Apartment
  module Sidekiq
    module Middleware
      # Runs a job in the tenant it was enqueued in, a job without one in the default tenant.
      class Server
        include ::Sidekiq::ServerMiddleware

        def call(_job_instance, job, _queue)
          Apartment::Tenant.switch(job['apartment']) do
            yield
          end
        end
      end
    end
  end
end
