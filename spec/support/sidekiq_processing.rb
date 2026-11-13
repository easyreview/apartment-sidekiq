# frozen_string_literal: true

require 'sidekiq/api'

module SidekiqProcessing
  # A Sidekiq process runs its processors in threads of their own, this one handles a single job in
  # the calling thread.
  class SingleJobProcessor < Sidekiq::Processor
    public :process_one
  end

  # Fetches the next job from Redis and runs it the way a Sidekiq process does: through the server
  # middleware, the retry handler and, for a job that dies, the dead set.
  def process_next_job
    SingleJobProcessor.new(Sidekiq.default_configuration.default_capsule).process_one
  end

  def enqueue_in(tenant, job_class)
    Apartment::Tenant.switch(tenant) { job_class.perform_async }
  end

  # A job pushed by a process without the client middleware.
  def enqueue_without_tenant(job_class)
    job_class.perform_async

    Sidekiq.redis do |connection|
      job = Sidekiq.load_json(connection.call('RPOP', 'queue:default'))
      job.delete('apartment')
      connection.call('LPUSH', 'queue:default', Sidekiq.dump_json(job))
    end
  end

  def queued_jobs
    Sidekiq::Queue.new('default').map(&:item)
  end

  def dead_jobs
    Sidekiq::DeadSet.new.to_a
  end

  def retries
    Sidekiq::RetrySet.new.to_a
  end

  def reported_errors
    ReportedErrors.all
  end

  # Whatever Sidekiq hands its error handlers.
  module ReportedErrors
    class << self
      def record(exception, context)
        all << { exception:, context: }
      end

      def all
        @all ||= []
      end
    end
  end
end
