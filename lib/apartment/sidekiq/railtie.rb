# frozen_string_literal: true

module Apartment
  module Sidekiq
    class Railtie < ::Rails::Railtie
      initializer 'apartment.sidekiq' do
        Middleware.run
      end
    end
  end
end
