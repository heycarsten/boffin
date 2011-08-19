require 'bundler/setup'
require 'rspec'
require 'redis'
require File.expand_path('../../lib/boffin', __FILE__)

$redis = Redis.connect

Boffin.config do |c|
  c.redis     = $redis
  c.namespace = 'boffin_test'
end

RSpec.configure do |config|
  config.before(:suite) do
    if (keys = $redis.keys('boffin_test*')).any?
      $reds.del(*keys)
    end
  end
end
