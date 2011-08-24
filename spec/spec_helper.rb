require 'bundler/setup'

require 'rspec'
require 'redis'
require 'timecop'

$redis = if ENV['DEBUG']
  require 'logger'
  Redis.connect(logger: Logger.new(STDERR))
else
  Redis.connect
end

require File.expand_path('../../lib/boffin', __FILE__)

Boffin.config do |c|
  c.redis     = $redis
  c.namespace = 'boffin_test'
end

class MockDitty
  attr :id
  def initialize(id = 1); @id = id end
end

# Just a different namespace to make the specs easier to follow.
class MockUser < MockDitty; end


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
