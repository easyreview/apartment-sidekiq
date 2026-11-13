# frozen_string_literal: true

# Sidekiq calls sidekiq_retry_in from its retry handler too, outside of the server middleware.
RSpec.describe 'A job that Sidekiq retries' do
  it 'runs its sidekiq_retry_in block in its tenant' do
    enqueue_in('tenant_a', TestJobs::RetryingJob)

    expect { process_next_job }.to raise_error(TestJobs::JobFailure)

    expect(TenantObservations.of(:retry_in)).to eq(tenant: 'tenant_a', schema: 'tenant_a')
    expect(Apartment::Tenant.current).to eq('public')
  end

  it 'is scheduled by what the block returns' do
    enqueue_in('tenant_a', TestJobs::RetryingJob)

    expect { process_next_job }.to raise_error(TestJobs::JobFailure)

    # Sidekiq adds up to 10 seconds of jitter to the first retry.
    expect(retries.map(&:at)).to contain_exactly(
      be_within(15).of(Time.now + TestJobs::RetryingJob::RETRY_DELAY)
    )
  end

  it 'dies when the block says so, with sidekiq_retries_exhausted in its tenant as well' do
    enqueue_in('tenant_b', TestJobs::KillingJob)

    expect { process_next_job }.to raise_error(TestJobs::JobFailure)

    expect(TenantObservations.of(:retry_in)).to eq(tenant: 'tenant_b', schema: 'tenant_b')
    expect(TenantObservations.of(:retries_exhausted)).to eq(tenant: 'tenant_b', schema: 'tenant_b')
    expect(dead_jobs.size).to eq(1)
  end
end
