# frozen_string_literal: true

module TestJobs
  class JobFailure < StandardError; end

  class SucceedingJob
    include Sidekiq::Job

    def perform
      TenantObservations.record(:perform)
    end
  end

  class FailingJob
    include Sidekiq::Job

    sidekiq_options retry: 0

    sidekiq_retries_exhausted do |_job, _exception|
      TenantObservations.record(:retries_exhausted)
    end

    def perform
      TenantObservations.record(:perform)
      raise JobFailure
    end
  end

  class InheritingFailingJob < FailingJob
  end

  class DiscardingJob
    include Sidekiq::Job

    sidekiq_options retry: 0

    sidekiq_retries_exhausted do |_job, _exception|
      :discard
    end

    def perform
      raise JobFailure
    end
  end

  class RetryingJob
    include Sidekiq::Job

    RETRY_DELAY = 3600

    sidekiq_options retry: 1

    sidekiq_retry_in do |_count, _exception, _job|
      TenantObservations.record(:retry_in)
      RETRY_DELAY
    end

    def perform
      raise JobFailure
    end
  end

  class KillingJob
    include Sidekiq::Job

    sidekiq_options retry: 5

    sidekiq_retry_in do |_count, _exception, _job|
      TenantObservations.record(:retry_in)
      :kill
    end

    sidekiq_retries_exhausted do |_job, _exception|
      TenantObservations.record(:retries_exhausted)
    end

    def perform
      raise JobFailure
    end
  end

  class SucceedingActiveJob < ActiveJob::Base
    def perform
      TenantObservations.record(:perform)
    end
  end

  class FailingActiveJob < ActiveJob::Base
    sidekiq_options retry: 0

    sidekiq_retries_exhausted do |_job, _exception|
      TenantObservations.record(:retries_exhausted)
    end

    def perform
      TenantObservations.record(:perform)
      raise JobFailure
    end
  end
end
