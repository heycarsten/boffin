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
  def initialize(id = 1); @id = id; end
end

# Just a different namespace to make the specs easier to follow.
class MockUser < MockDitty; end

class MockMember
  attr :as_member
  def initialize(id = 1); @as_member = id; end
end

class MockTrackableIncluded < MockDitty
  include Boffin::Trackable
  boffin.hit_types = [:views, :likes]
end

class MockTrackableInjected < MockDitty
  Boffin.track(self, [:views, :likes])
end

module SpecHelper
  module_function
  def flush_keyspace!
    if (keys = $redis.keys("#{Boffin.config.namespace}*")).any?
      $redis.del(*keys)
    end
  end
end
