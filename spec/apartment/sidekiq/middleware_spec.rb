# frozen_string_literal: true

RSpec.describe Apartment::Sidekiq::Middleware do
  let(:configuration) { Sidekiq.default_configuration }

  it 'is installed by the railtie while the application boots' do
    expect(configuration.client_middleware.exists?(Apartment::Sidekiq::Middleware::Client)).to be(true)
    expect(configuration.server_middleware.exists?(Apartment::Sidekiq::Middleware::Server)).to be(true)
  end

  describe '.run' do
    let(:earlier_middleware) do
      Class.new do
        def call(_job_instance, _job, _queue)
          yield
        end
      end
    end

    after do
      configuration.server_middleware.remove(earlier_middleware)
    end

    it 'puts the server middleware first, so that every other one runs in the tenant of the job as well' do
      configuration.server_middleware.prepend(earlier_middleware)

      described_class.run

      expect(configuration.server_middleware.map(&:klass).first).to eq(Apartment::Sidekiq::Middleware::Server)
    end

    it 'installs each middleware once' do
      described_class.run

      expect(configuration.client_middleware.count { |entry| entry.klass == Apartment::Sidekiq::Middleware::Client }).to eq(1)
      expect(configuration.server_middleware.count { |entry| entry.klass == Apartment::Sidekiq::Middleware::Server }).to eq(1)
    end
  end
end
