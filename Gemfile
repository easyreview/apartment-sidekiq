source 'https://rubygems.org'

gemspec

# CI tests each supported combination by setting these, see .github/workflows/ci.yml.
sidekiq_version = ENV['SIDEKIQ_VERSION'].to_s
rails_version = ENV['RAILS_VERSION'].to_s
sidekiq_version = '~> 8.1.0' if sidekiq_version.empty?
rails_version = '~> 8.1.0' if rails_version.empty?

gem 'sidekiq', sidekiq_version
gem 'activejob', rails_version
gem 'activerecord', rails_version
gem 'railties', rails_version

gem 'pg'
gem 'rake'
gem 'rspec'
