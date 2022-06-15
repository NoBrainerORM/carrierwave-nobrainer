# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

Gem::Specification.new do |s|
  s.name        = 'carrierwave-nobrainer'
  s.version     = '0.2.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Nicolas Viennot']
  s.email       = ['nicolas@viennot.biz']
  s.homepage    = 'https://github.com/NoBrainerORM/carrierwave-nobrainer'
  s.summary     = 'NoBrainer adapter for Carrierwave'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 1.9.0'

  s.metadata['allowed_push_host'] = 'https://rubygems.org'
  s.metadata['homepage_uri'] = spec.homepage
  s.metadata['source_code_uri'] = spec.homepage
  s.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  s.files        = Dir['lib/**/*'] + ['README.md']
  s.require_path = 'lib'

  s.add_dependency 'carrierwave', '>= 0.10.0'
  s.add_dependency 'nobrainer', '>= 0.24.0'
end
