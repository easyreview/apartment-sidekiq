# frozen_string_literal: true

RSpec.describe Apartment::Sidekiq::Middleware::Server do
  it 'runs a job in the tenant it was enqueued in' do
    enqueue_in('tenant_a', TestJobs::SucceedingJob)

    process_next_job

    expect(TenantObservations.of(:perform)).to eq(tenant: 'tenant_a', schema: 'tenant_a')
  end

  it 'runs an ActiveJob job in its tenant' do
    Apartment::Tenant.switch('tenant_b') { TestJobs::SucceedingActiveJob.perform_later }

    process_next_job

    expect(TenantObservations.of(:perform)).to eq(tenant: 'tenant_b', schema: 'tenant_b')
  end

  it 'leaves the tenant again afterwards' do
    enqueue_in('tenant_a', TestJobs::SucceedingJob)

    process_next_job

    expect(Apartment::Tenant.current).to eq('public')
    expect(TenantObservations.current_schema).to eq('public')
  end

  it 'runs a job without a tenant in the default tenant' do
    enqueue_without_tenant(TestJobs::SucceedingJob)

    Apartment::Tenant.switch('tenant_a') { process_next_job }

    expect(TenantObservations.of(:perform)).to eq(tenant: 'public', schema: 'public')
  end

  it 'refuses a job whose tenant no longer exists' do
    Sidekiq::Client.push('class' => TestJobs::SucceedingJob, 'args' => [], 'apartment' => MISSING_TENANT)

    expect { process_next_job }.to raise_error(Apartment::TenantNotFound)

    expect(TenantObservations.of(:perform)).to be_nil
    expect(retries.size).to eq(1)
  end
end
