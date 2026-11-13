# frozen_string_literal: true

# Sidekiq calls sidekiq_retries_exhausted from its retry handler, which wraps the server middleware:
# by then the middleware has left the tenant of the job again.
RSpec.describe 'A job that exhausts its retries' do
  it 'runs its sidekiq_retries_exhausted block in its tenant' do
    enqueue_in('tenant_a', TestJobs::FailingJob)

    expect { process_next_job }.to raise_error(TestJobs::JobFailure)

    expect(TenantObservations.of(:retries_exhausted)).to eq(tenant: 'tenant_a', schema: 'tenant_a')
  end

  it 'leaves the tenant again afterwards' do
    enqueue_in('tenant_a', TestJobs::FailingJob)

    expect { process_next_job }.to raise_error(TestJobs::JobFailure)

    expect(Apartment::Tenant.current).to eq('public')
    expect(TenantObservations.current_schema).to eq('public')
  end

  it 'runs a block it inherits in its tenant' do
    enqueue_in('tenant_b', TestJobs::InheritingFailingJob)

    expect { process_next_job }.to raise_error(TestJobs::JobFailure)

    expect(TenantObservations.of(:retries_exhausted)).to eq(tenant: 'tenant_b', schema: 'tenant_b')
  end

  it 'runs the block of an ActiveJob job in its tenant' do
    Apartment::Tenant.switch('tenant_b') { TestJobs::FailingActiveJob.perform_later }

    expect { process_next_job }.to raise_error(TestJobs::JobFailure)

    expect(TenantObservations.of(:retries_exhausted)).to eq(tenant: 'tenant_b', schema: 'tenant_b')
  end

  it 'still goes to the dead set' do
    jid = enqueue_in('tenant_a', TestJobs::FailingJob)

    expect { process_next_job }.to raise_error(TestJobs::JobFailure)

    expect(dead_jobs.map(&:jid)).to eq([jid])
  end

  it 'hands Sidekiq what the block returns' do
    enqueue_in('tenant_a', TestJobs::DiscardingJob)

    expect { process_next_job }.to raise_error(TestJobs::JobFailure)

    expect(dead_jobs).to be_empty
  end

  context 'without a tenant in the job' do
    it 'runs the block in the default tenant, like the job itself' do
      enqueue_without_tenant(TestJobs::FailingJob)

      Apartment::Tenant.switch('tenant_a') do
        expect { process_next_job }.to raise_error(TestJobs::JobFailure)
      end

      expect(TenantObservations.of(:perform)).to eq(tenant: 'public', schema: 'public')
      expect(TenantObservations.of(:retries_exhausted)).to eq(tenant: 'public', schema: 'public')
    end
  end

  context 'when the tenant of the job no longer exists' do
    it 'reports that instead of running the block outside of the tenant, and the job still dies' do
      jid = Sidekiq::Client.push('class' => TestJobs::FailingJob, 'args' => [], 'apartment' => MISSING_TENANT)

      expect { process_next_job }.to raise_error(Apartment::TenantNotFound)

      expect(TenantObservations.of(:retries_exhausted)).to be_nil
      expect(reported_errors).to include(
        exception: an_instance_of(Apartment::TenantNotFound),
        context: a_hash_including(context: 'Error calling retries_exhausted')
      )
      expect(dead_jobs.map(&:jid)).to eq([jid])
      expect(Apartment::Tenant.current).to eq('public')
    end
  end
end
