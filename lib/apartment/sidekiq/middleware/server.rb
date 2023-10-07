module Apartment::Sidekiq::Middleware
  class Server
    include Sidekiq::ServerMiddleware

    def call(job_instance, msg, queue)
      Apartment::Tenant.switch(msg['apartment']) do
        yield
      end
    end
  end
end
