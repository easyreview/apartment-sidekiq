# 3.0.0 (unreleased)

First release of easyreview's fork.

## Fixes
  * `sidekiq_retries_exhausted` and `sidekiq_retry_in` blocks run in the tenant of the job. Sidekiq calls them from its retry handler, which wraps the server middleware, so they ran in whatever tenant the Sidekiq thread was in, usually the default one. Covers ActiveJob jobs and inherited blocks. If the tenant no longer exists, the block does not run and Sidekiq reports the `Apartment::TenantNotFound` to its error handlers.

## BREAKING CHANGES
  * The server middleware is prepended to the chain, so that every other server middleware runs in the tenant of the job. This replaces the special case for the batch middleware of Sidekiq Pro.
  * Requires Ruby 3.3 or newer, Sidekiq 7.3 up to 8.x and ros-apartment 3.x.
  * Removed `Apartment::Sidekiq::Middleware::Honeybadger::Server`, which the gem never installed.

## Development
  * Specs that run jobs through Sidekiq's processor against PostgreSQL schemas and Redis, a Docker setup and GitHub Actions CI for the supported combinations of Ruby, Sidekiq and Rails.

# 2.0.0 (2023-10-7)

## BREAKING CHANGES
  * Sidekiq 7+ support, refaactor to use Sidekiq's new internal middleware API. This means that this gem is no longer compatible with Sidekiq 6.5 or earlier. If you need to use earlier versions please use the 1.2 version of this gem. [@acallaghan]

# 1.2.0 (2017-12-17)

  * [#16](https://github.com/influitive/apartment-sidekiq/pull/16): Sidekiq::Batch compatibility [@mperham]
  * [#20](https://github.com/influitive/apartment-sidekiq/issues/20): Relax apartment version in gemspec [@MSeneadza]
    * @jhubert, @JanStevens and @1990prashant also opened issues/pull requests about this problem
  * [#24](https://github.com/influitive/apartment-sidekiq/pull/24): Fix Sidekiq Pro Batch Lookup [@JanStevens]
