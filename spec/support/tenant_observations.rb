# frozen_string_literal: true

# Where job code ran: the tenant Apartment reports and the schema the database connection is on.
module TenantObservations
  class << self
    def record(label)
      observations[label] = { tenant: Apartment::Tenant.current, schema: current_schema }
    end

    def of(label)
      observations[label]
    end

    def clear
      observations.clear
    end

    def current_schema
      ActiveRecord::Base.with_connection { |connection| connection.select_value('SELECT current_schema()') }
    end

    protected

    def observations
      @observations ||= {}
    end
  end
end
