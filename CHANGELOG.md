# master (unreleased)

# 2.0.0 (2023-10-7)

## BREAKING CHANGES
  * Sidekiq 7+ support, refaactor to use Sidekiq's new internal middleware API. This means that this gem is no longer compatible with Sidekiq 6.5 or earlier. If you need to use earlier versions please use the 1.2 version of this gem. [@acallaghan]

# 1.2.0 (2017-12-17)

  * [#16](https://github.com/influitive/apartment-sidekiq/pull/16): Sidekiq::Batch compatibility [@mperham]
  * [#20](https://github.com/influitive/apartment-sidekiq/issues/20): Relax apartment version in gemspec [@MSeneadza]
    * @jhubert, @JanStevens and @1990prashant also opened issues/pull requests about this problem
  * [#24](https://github.com/influitive/apartment-sidekiq/pull/24): Fix Sidekiq Pro Batch Lookup [@JanStevens]
