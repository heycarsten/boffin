require 'base64'
require 'date'
require 'time'
require 'redis'
require 'boffin/version'
require 'boffin/utils'
require 'boffin/config'
require 'boffin/keyspace'
require 'boffin/tracker'
require 'boffin/hit'
require 'boffin/trackable'

# Boffin is a library for tracking hits to things in your Ruby application.
# Things can be IDs of records in a database, strings representing tags or
# topics, URLs of webpages, names of places, whatever you desire. Boffin is able
# to provide lists of those things based on most hits, least hits, it can even
# report on weighted combinations of different types of hits.
#
# Refer to the {file:README} for further information and examples.
module Boffin
  # The member to use when no session identifier is available for unique hit
  # tracking
  NIL_SESSION_MEMBER = 'boffin:nilsession'

  # The way Time should be formatted for each interval type
  INTERVAL_FORMATS = {
    :hours  => '%F-%H',
    :days   => '%F',
    :months => '%Y-%m' }

  # Different interval types
  INTERVAL_TYPES = INTERVAL_FORMATS.keys

  # Raised by Tracker when hit types are passed to it that are not included in
  # its list of valid hit types.
  class UndefinedHitTypeError < StandardError; end

  # Set or get the default Config instance
  # @param [Hash] opts
  #   (see {Config#initialize})
  # @return [Config]
  #   the default Config instance
  # @yield [Config.new]
  #   Passes the block to {Config#initialize}
  # @example Getting the default config instance
  #   Boffin.config
  # @example Setting the default config instance with a block
  #   Boffin.config do |conf|
  #     conf.namespace = 'something:special'
  #   end
  # @example Setting the default config instance with a Hash
  #   Boffin.config(namespace: 'something:cool')
  def self.config(opts = {}, &block)
    @config ||= Config.new(opts, &block)
  end

  # Creates a new Tracker instance. If passed a class, Trackable is injected
  # into it.
  # @param [Class, Symbol] class_or_ns
  #   A class or symbol to use as a namespace for the Tracker
  # @param [optional Array <Symbol>] hit_types
  #   A list of valid hit types for the Tracker
  # @return [Tracker]
  # @example Tracking an ActiveRecord model
  #   Boffin.track(MyModel, [:views, :likes])
  #
  #   # This does the same thing:
  #   class MyModel
  #     include Boffin::Tracker
  #     boffin.hit_types = [:views, :likes]
  #   end
  # @example Creating a tracker without fancy injecting-ness
  #   ThingsTracker = Boffin.track(:things)
  #
  #   # This does the same thing:
  #   ThingsTracker = Boffin::Tracker.new(:things)
  def self.track(class_or_ns, hit_types = [])
    case class_or_ns
    when String, Symbol
      Tracker.new(class_or_ns, hit_types)
    else
      class_or_ns.send(:include, Trackable)
      class_or_ns.boffin.hit_types = hit_types
      class_or_ns.boffin
    end
  end
end
