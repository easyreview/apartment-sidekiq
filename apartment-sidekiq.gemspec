# frozen_string_literal: true

require_relative 'lib/apartment/sidekiq/version'

Gem::Specification.new do |spec|
  spec.name = 'ros-apartment-sidekiq'
  spec.version = Apartment::Sidekiq::VERSION
  spec.authors = ['Brad Robertson', 'Rui Baltazar', 'easyreview']
  spec.summary = 'Sidekiq support for ros-apartment'
  spec.description = 'Runs each Sidekiq job, and the retry callbacks Sidekiq calls for it, in the Apartment tenant it was enqueued in.'
  spec.homepage = 'https://github.com/easyreview/apartment-sidekiq'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3'
  spec.metadata = {
    'source_code_uri' => spec.homepage,
    'changelog_uri' => "#{spec.homepage}/blob/master/CHANGELOG.md"
  }

  spec.files = Dir.glob(['lib/**/*.rb', 'CHANGELOG.md', 'LICENSE.txt', 'README.md'], base: __dir__)
  spec.require_paths = ['lib']

  spec.add_dependency 'ros-apartment', '>= 3.0', '< 4'
  # Wraps the blocks of Sidekiq::Job::Options::ClassMethods, see lib/apartment/sidekiq/job_callbacks.rb.
  spec.add_dependency 'sidekiq', '>= 7.3', '< 9'
end
