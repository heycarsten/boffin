module Boffin
  class Keyspace

    def initialize(config = Config.new)
      @config = config
    end

    # boffin:profile
    def root(ns)
      "#{@config.namespace}:#{Utils.underscore(ns)}"
    end

    # boffin:profile:views:hits
    def hits_key(ns, *types)
      "#{root(ns)}:#{types.flatten.join('_')}:hits"
    end

    # boffin:profile:views:hits:current.5
    def hits_union_key(ns, types, days)
      "#{hits_key(ns, types)}:current.#{days}"
    end

    # boffin:profile:views_1.likes_3:hits:current.5
    def combi_hits_union_key(ns, weighted_hit_types, days)
      types = weighted_hit_types.map { |type, weight| "#{type}_#{weight}" }
      hits_union_key(ns, types, days)
    end

    # boffin:profile:views.<window>
    def hits_window_key(ns, types, window)
      "#{hits_key(ns, types)}.#{window}"
    end

    # boffin:profile:views.2011-01-01-23
    def hits_hour_window_key(ns, types, time)
      hits_window_key(ns, types, time.strftime('%F-%H'))
    end

    # boffin:profile:views.2011-01-01
    def hits_day_window_key(ns, types, time)
      hits_window_key(ns, types, time.strftime('%F'))
    end

    # boffin:profile:views.2011-01
    def hits_month_window_key(ns, types, time)
      hits_window_key(ns, types, time.strftime('%Y-%m'))
    end

    # boffin:profile.6:views
    def object_root(ns, type, object_id_slug)
      "#{root(ns)}:#{object_id_slug}.#{type}"
    end

    # boffin:profile.6:views.hits
    def object_hits_key(ns, object_id_slug, type)
      "#{object_root(ns, type, object_id_slug)}.hits"
    end

    # boffin:profile.6:views.hit_count
    def object_hit_count_key(ns, object_id_slug, type)
      "#{object_root(ns, type, object_id_slug)}.hit_count"
    end

  end
end
