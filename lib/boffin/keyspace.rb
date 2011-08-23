module Boffin
  class Keyspace

    attr_reader :config

    def initialize(tracker, is_uniq = false)
      @config = tracker.config
      @ns     = tracker.namespace
      @uniq   = is_uniq ? true : false
    end

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

    def trending_union(weighted_hit_types, unit, size)
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
      hits_window(types, time.strftime(WINDOW_UNIT_FORMATS[unit]))
    end

  end
end
