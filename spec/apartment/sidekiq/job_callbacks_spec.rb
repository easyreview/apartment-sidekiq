# frozen_string_literal: true

RSpec.describe 'The retry callbacks of a job' do
  it 'switch to the tenant of the job whoever calls them' do
    TestJobs::FailingJob.sidekiq_retries_exhausted_block.call({ 'apartment' => 'tenant_a' }, TestJobs::JobFailure.new)
    TestJobs::RetryingJob.sidekiq_retry_in_block.call(0, TestJobs::JobFailure.new, { 'apartment' => 'tenant_b' })

    expect(TenantObservations.of(:retries_exhausted)).to eq(tenant: 'tenant_a', schema: 'tenant_a')
    expect(TenantObservations.of(:retry_in)).to eq(tenant: 'tenant_b', schema: 'tenant_b')
  end

  it 'stay unset when registered without a block' do
    job_class = Class.new do
      include Sidekiq::Job

      sidekiq_retry_in
      sidekiq_retries_exhausted
    end

    expect(job_class.sidekiq_retry_in_block).to be_nil
    expect(job_class.sidekiq_retries_exhausted_block).to be_nil
  end
end
