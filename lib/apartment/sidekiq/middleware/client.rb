module Apartment::Sidekiq::Middleware
  class Client
    include Sidekiq::ClientMiddleware

    def call(job_class, msg, queue, redis_pool)
      msg["apartment"] ||= Apartment::Tenant.current
      yield
    end
  end
end