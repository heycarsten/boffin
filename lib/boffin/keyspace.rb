module Boffin
  class Keyspace

    WINDOW_UNIT_FORMATS = {
      hour:  '%F-%H',
      day:   '%F',
      month: '%Y-%m'
    }

    def initialize(config = Config.new)
      @config = config
    end

    def root(ns)
      "#{@config.namespace}:#{Utils.underscore(ns)}"
    end

    def hits_key(ns, *types)
      "#{root(ns)}:#{types.flatten.join('_')}:hits"
    end

    def hits_union_key(ns, types, unit, size)
      "#{hits_key(ns, types)}:current.#{unit}_#{size}"
    end

    def combi_hits_union_key(ns, weighted_hit_types, unit, size)
      types = weighted_hit_types.map { |type, weight| "#{type}_#{weight}" }
      hits_union_key(ns, types, unit, size)
    end

    def hits_window_key(ns, types, window)
      "#{hits_key(ns, types)}.#{window}"
    end

    def hits_time_window_key(ns, types, unit, time)
      hits_window_key(ns, types, time.strftime(WINDOW_UNIT_FORMATS[unit]))
    end

    def object_root(ns, object_id_slug, type)
      "#{root(ns)}.#{object_id_slug}:#{type}"
    end

    def object_hits_key(ns, object_id_slug, type)
      "#{object_root(ns, object_id_slug, type)}.hits"
    end

    def object_hit_count_key(ns, object_id_slug, type)
      "#{object_root(ns, object_id_slug, type)}.hit_count"
    end

  end
end
