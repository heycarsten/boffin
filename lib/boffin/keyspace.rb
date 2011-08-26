module Boffin
  # Responsible for generating keys to store hit data in Redis.
  class Keyspace

    attr_reader :config

    # @param [Tracker] tracker
    #   The Tracker that is using this Keyspace
    # @param [true, false] is_uniq
    #   If specified all keys will include .uniq after the root portion. Used
    #   for easily scoping data for tracking unique hits.
    def initialize(tracker, is_uniq = false)
      @config = tracker.config
      @ns     = tracker.namespace
      @uniq   = is_uniq ? true : false
    end

    # @return [true, false]
    #   `true` if this keyspace is scoped for unique data
    def unique_namespace?
      @uniq
    end

    # @param [Object] instance
    #   Object that will be used to prefix the key namespace this is used for
    #   keys that deal with object instances. (See {Utils#object_as_key})
    # @return [String]
    #   The root portion of a key: `boffin:listing`, `boffin:listing.5`, or
    #   `boffin:listing.5:uniq`
    def root(instance = nil)
      slug = instance ? Utils.object_as_key(instance) : nil
      "#{@config.namespace}:#{@ns}".tap { |s|
        s << ".#{slug}" if slug
        s << ":uniq"    if @uniq }
    end

    # @param [Array<Symbol>, Symbol] types
    #   An array of hit types `[:views, :likes]`, or a singular hit type
    #   `:views`
    # @param [Object] instance
    #   If provided, the keyspace will be scoped to a particilar instance, used
    #   for hit counters: `boffin:listing.<instance>`
    # @return [String]
    #   The root portion of the hits keyspace: `boffin:listing:views`,
    #   `boffin:listing.5:views`
    def hits_root(types, instance = nil)
      "#{root(instance)}:#{[types].flatten.join('_')}"
    end

    # Calculates the hit root and postfixes it with ":hits", this key is used
    # for a sorted set that stores unique hit count data.
    # @param [Array<Symbol>, Symbol] types
    # @param [Object] instance
    # @return [String]
    # @see #hits_root
    def hits(types, instance = nil)
      "#{hits_root(types, instance)}:hits"
    end

    # Calculates the hit root and postfixes it with ":hit_count", this key is
    # used to store a count of total hits ever made.
    # @param [Array<Symbol>, Symbol] types
    # @param [Object] instance
    # @return [String]
    # @see #hits_root
    def hit_count(types, instance)
      "#{hits_root(types, instance)}:hit_count"
    end

    # Returns a key that is used for storing the result set of a union for the
    # provided window of time. Calls {#hits}, and then appends
    # `:current.<unit>_<size>`
    # @param [Array<Symbol>, Symbol] types
    # @param [Symbol] unit
    #   The time interval: `:hours`, `:days`, or `:months`
    # @param [Fixnum] size
    #   The window size of the specified time interval being calculated
    # @return [String]
    # @see #hits
    def hits_union(types, unit, size)
      "#{hits(types)}:current.#{unit}_#{size}"
    end

    # Returns a key that is used for storing the result set of a union of hit
    # unions.
    # @param [Hash] weighted_hit_types
    #   The types and weights of hits of which a union was calculated:
    #   `{ views: 1, likes: 2 }`
    # @param [Symbol] unit
    #   The time interval: `:hours`, `:days`, or `:months`
    # @param [Fixnum] size
    #   The window size of the specified time interval being calculated
    # @return [String]
    # @see #hits_union
    def hits_union_multi(weighted_hit_types, unit, size)
      types = weighted_hit_types.map { |type, weight| "#{type}_#{weight}" }
      hits_union(types, unit, size)
    end

    # Generates a key that is used for storing hit data for a particular
    # interval in time. You'll probably want to use {#hits_time_window} as it
    # will generate the window string for you.
    # @param [Symbol] type
    #   The hit type that will use the generated key
    # @param [String] window
    #   Represents a period of time: `"2011-01-01-01"`, `"2011-01-01"`,
    #   `"2011-01"`
    # @return [String]
    # @see #hits
    # @see #hits_time_window
    def hits_window(type, window)
      "#{hits(type)}.#{window}"
    end

    # Generates keys for each interval in the calculated range of time
    # @param [Symbol] type
    #   The hit type that will use the generated key
    # @param [Symbol] unit
    #   The time interval: `:hours`, `:days`, or `:months`
    # @param [Fixnum] size
    #   The window size of the specified time interval being calculated
    # @param [Time, Date] starting_at
    #   The time at which to start counting back from
    # @return [Array<String>]
    #   An array of keys for the range of intervals
    # @see #hits_time_window
    # @see Utils#time_ago_range
    def hit_time_windows(type, unit, size, starting_at = Time.now)
      Utils.time_ago_range(starting_at, unit => size).
        map { |time| hits_time_window(type, unit, time) }
    end

    # Generates a key for a sorted set that is used to store hit data for a
    # particular interval of time. For example, the `:days` interval of
    # 2011-08-26 11:24:41 would be 2011-08-26.
    # @param [Symbol] type
    #   The hit type that will use the generated key
    # @param [Symbol] unit
    #   The time interval: `:hours`, `:days`, or `:months`
    # @param [Time] time
    #   The time for which to extract an interval from.
    def hits_time_window(type, unit, time)
      hits_window(type, time.strftime(INTERVAL_FORMATS[unit]))
    end

  end
end
