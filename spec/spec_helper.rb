# frozen_string_literal: true

require 'rubygems'
require 'bundler'
require 'fileutils'
Bundler.require(:default, ENV['CI'] ? :ci : :development)

SPEC_ROOT = File.expand_path File.dirname(__FILE__)
Dir["#{SPEC_ROOT}/support/**/*.rb"].sort.each do |f|
  require f unless File.basename(f) =~ /^_/
end

database_host = ENV['DB_HOST'] || 'localhost'
db_name       = ENV['DB_NAME'] || 'nobrainer_test'

nobrainer_conf = proc do |c|
  c.reset!
  c.app_name = :carrierwave
  c.rethinkdb_url = "rethinkdb://#{database_host}/#{db_name}"
  c.environment = :test
  c.logger = Logger.new($stderr).tap do |l|
    l.level = ENV['DEBUG'] ? Logger::DEBUG : Logger::WARN
  end
end

ROOT_DIR = "#{SPEC_ROOT}/tmp/root"
CACHE_DIR = "#{SPEC_ROOT}/tmp/cache_dir"

CarrierWave.configure do |config|
  config.root = ROOT_DIR
  config.cache_dir = CACHE_DIR
end

RSpec.configure do |config|
  config.order = :random
  config.color = true
  config.expect_with :rspec do |c|
    c.syntax = %i[should expect]
  end

  config.before(:each) do
    NoBrainer.configure(&nobrainer_conf)
    NoBrainer.purge!
    NoBrainer::Loader.cleanup
    Dir["#{ROOT_DIR}/*"].each { |path| FileUtils.rm_rf(path) }
    Dir["#{CACHE_DIR}/*"].each { |path| FileUtils.rm_rf(path) }
  end
end
