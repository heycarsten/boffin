require 'bundler/setup'

require 'rspec'
require 'redis'
require 'timecop'

require File.expand_path('../../lib/boffin', __FILE__)

$redis     = Redis.connect
$boffspace = (ENV['BOFFSPACE'] || 'boffin_test')

Boffin.config do |c|
  c.redis     = $redis
  c.namespace = $boffspace
end

module BoffinSpecHelper
  module_function
  def clear_redis_keyspace!
    if (keys = $redis.keys("#{$boffspace}*")).any?
      $redis.del(*keys)
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    BoffinSpecHelper.clear_redis_keyspace!
  end
end
