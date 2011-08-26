module Boffin
  # Responsible for generating keys to store hit data in Redis.
  class Keyspace

    attr_reader :config

    # @param [Tracker] tracker
    #   The Tracker that is using this Keyspace
    # @param [Boolean] is_uniq
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
    #   Returns the root portion of a key
    def root(instance = nil)
      slug = instance ? Utils.object_as_key(instance) : nil
      "#{@config.namespace}:#{@ns}".tap { |s|
        s << ".#{slug}" if slug
        s << ".uniq"    if @uniq }
    end

    def hits_root(types, instance = nil)
      "#{root(instance)}:#{[types].flatten.join('_')}"
    end

    def hits(types, instance = nil)
      "#{hits_root(types, instance)}:hits"
    end

    def hit_count(types, instance)
      "#{hits_root(types, instance)}:hit_count"
    end

    def hits_union(types, unit, size)
      "#{hits(types)}:current.#{unit}_#{size}"
    end

    def hits_union_multi(weighted_hit_types, unit, size)
      types = weighted_hit_types.map { |type, weight| "#{type}_#{weight}" }
      hits_union(types, unit, size)
    end

    def hits_window(types, window)
      "#{hits(types)}.#{window}"
    end

    def hit_time_windows(types, unit, size, starting_at = Time.now)
      Utils.time_ago_range(starting_at, unit => size).
        map { |time| hits_time_window(types, unit, time) }
    end

    def hits_time_window(types, unit, time)
      hits_window(types, time.strftime(INTERVAL_FORMATS[unit]))
    end

  end
end
