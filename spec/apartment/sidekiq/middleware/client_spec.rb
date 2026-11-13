# frozen_string_literal: true

RSpec.describe Apartment::Sidekiq::Middleware::Client do
  it 'stores the tenant a job is enqueued in' do
    enqueue_in('tenant_a', TestJobs::SucceedingJob)

    expect(queued_jobs.map { |job| job['apartment'] }).to eq(['tenant_a'])
  end

  it 'stores the tenant of an ActiveJob job' do
    Apartment::Tenant.switch('tenant_b') { TestJobs::SucceedingActiveJob.perform_later }

    expect(queued_jobs.map { |job| job['apartment'] }).to eq(['tenant_b'])
  end

  it 'keeps a tenant the job names already' do
    Apartment::Tenant.switch('tenant_a') do
      Sidekiq::Client.push('class' => TestJobs::SucceedingJob, 'args' => [], 'apartment' => 'tenant_b')
    end

    expect(queued_jobs.map { |job| job['apartment'] }).to eq(['tenant_b'])
  end
end
