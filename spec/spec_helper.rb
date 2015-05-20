require 'rubygems'
require 'bundler'
require 'fileutils'
Bundler.require(:default, ENV['CI'] ? :ci : :development)

SPEC_ROOT = File.expand_path File.dirname(__FILE__)
Dir["#{SPEC_ROOT}/support/**/*.rb"].each { |f| require f unless File.basename(f) =~ /^_/ }

NoBrainer.configure do |config|
  config.app_name = :carrierwave
  config.environment = :test
end

ROOT_DIR = "#{SPEC_ROOT}/tmp/root"
CACHE_DIR = "#{SPEC_ROOT}/tmp/cache_dir"

CarrierWave.configure do |config|
  config.root = ROOT_DIR
  config.cache_dir = CACHE_DIR
end

RSpec.configure do |config|
  config.color = true
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  config.before(:each) do
    NoBrainer.purge!
    Dir["#{ROOT_DIR}/*"].each { |path| FileUtils.rm_rf(path) }
    Dir["#{CACHE_DIR}/*"].each { |path| FileUtils.rm_rf(path) }
  end
end
