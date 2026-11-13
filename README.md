# Apartment::Sidekiq

Sidekiq support for [ros-apartment](https://github.com/rails-on-services/apartment): each job runs in
the tenant it was enqueued in, and so do the retry callbacks Sidekiq calls for it.

This is easyreview's fork of
[rails-on-services/apartment-sidekiq](https://github.com/rails-on-services/apartment-sidekiq), by way of
[acallaghan/apartment-sidekiq](https://github.com/acallaghan/apartment-sidekiq), which brought Sidekiq 7
support. Neither is maintained anymore. See the [changelog](CHANGELOG.md) for what changed here.

## Installation

The gem is not on RubyGems, install it from GitHub:

```ruby
gem 'ros-apartment-sidekiq', github: 'easyreview/apartment-sidekiq', require: 'apartment-sidekiq'
```

In a Rails application its railtie installs the middleware. Without Rails, call
`Apartment::Sidekiq::Middleware.run` once while your application boots.

Load the gem before your jobs, as `Bundler.require` does: it makes the retry callbacks of a job
tenant-aware when the job class registers them.

## What it does

- **Client middleware:** stores `Apartment::Tenant.current` in the job as `apartment`, unless the job
  names a tenant already.
- **Server middleware:** runs the job inside `Apartment::Tenant.switch(job['apartment'])`. It goes to
  the front of the server middleware chain, so that the other server middleware runs in the tenant of
  the job as well.
  A job without a tenant runs in the default tenant. A job whose tenant does not exist fails with
  `Apartment::TenantNotFound` and is retried like any other failing job.
- **Retry callbacks:** Sidekiq calls the `sidekiq_retry_in` and `sidekiq_retries_exhausted` blocks of a
  job from its retry handler, which wraps the server middleware, so these blocks used to run outside of
  the tenant of the job. Now each of them switches to the tenant of the job it is called for, for
  ActiveJob jobs and inherited blocks as well. If that tenant no longer exists, the block does not run:
  Sidekiq hands the `Apartment::TenantNotFound` to its error handlers, as it does with any error of
  the block, and the job dies all the same.

## What it leaves alone

- **Death handlers** (`config.death_handlers`) are global. Sidekiq calls them for jobs that ran out of
  retries, jobs with `retry: false`, discarded jobs and jobs killed through the Web UI or the API. They
  run outside of the tenant of the job, `job['apartment']` names it.
- **Other per-job state:** the retry callbacks run outside of the server middleware chain, so whatever
  other server middleware sets up for a job is not set up around them.
- **`Sidekiq::Testing`** runs jobs through a middleware chain of its own. Add
  `Apartment::Sidekiq::Middleware::Server` to `Sidekiq::Testing.server_middleware` if your tests depend
  on the tenant switch.

## ActiveJob

With Sidekiq's ActiveJob adapter, ActiveJob jobs pass through the same middleware and get the same
retry callbacks. [ros-apartment-activejob](https://github.com/rails-on-services/apartment-activejob) is
not needed for them. It does no harm either: it switches to the tenant it stored when the job was
enqueued, which is the same.

## Compatibility

| Dependency    | Versions        |
|---------------|-----------------|
| Ruby          | 3.3 to 4.0      |
| Sidekiq       | 7.3 to 8.x      |
| ros-apartment | 3.x             |
| Rails         | 7.2 to 8.1, for the railtie and ActiveJob |

## Development

The specs run Sidekiq's processor against PostgreSQL schemas and Redis, in Docker:

```sh
docker compose run --rm ruby bash -c 'bundle install && bundle exec rspec'
```

`RUBY_VERSION`, `SIDEKIQ_VERSION` and `RAILS_VERSION` select another combination, for example
`RUBY_VERSION=3.3 SIDEKIQ_VERSION='~> 7.3.0' RAILS_VERSION='~> 7.2.0'` (add `--build` to `run` for a new
Ruby version). The CI tests the combinations listed in `.github/workflows/ci.yml`.
