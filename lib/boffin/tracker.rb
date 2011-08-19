module Boffin
  class Tracker

    WINDOWS = [:hour, :day, :month]

    attr_reader :config, :ks

    def initialize(config = Config.new)
      @config = config
      @ks = Keyspace.new(@config)
    end

    def hit(ns, thing, type, *uniquenesses, opts)
      opts ||= {}
      time   = Time.now
      member = mk_hit_member(uniquenesses, opts[:unique])
      id     = mk_object_id(thing)
      rdb.incr(@ks.object_hit_count_key(ns, id, type))
      if rdb.sadd(@ks.object_hits_key(ns, id, type), member)
        store_windows(time, ns, thing, id, type, true)
      else
        store_windows(time, ns, thing, id, type, false)
      end
    end

    def uhit(ns, thing, type, *uniquenesses)
      hit(ns, thing, type, *uniquenesses, unique: true)
    end

    def hit_count(ns, thing, type)
      id = mk_object_id(thing)
      rdb.get(@ks.object_hit_count_key(ns, id, type)).to_i
    end

    def unique_hit_count(ns, thing, type)
      id = mk_object_id(thing)
      rdb.scard(@ks.object_hits_key(ns, id, type)).to_i
    end

    def top(ns, type, days)
      key = @ks.hits_union_key(ns, type, days)
      
    end

    def utop(ns, type, days)
      warn('utop')
      top(days, "#{ns}.uniq", type)
    end

    def trending(ns, days, weighted_types)
      
    end

    def utrending(ns, days, weighted_types)
      warn('utrending')
      trending(days, "#{ns}.uniq", weighted_types)
    end

    def top_ids(type, days = 7)
      storkey = rdb_stored_hits_union_key(type, days)
      dates   = (((days-1).days.ago.to_date)..(Date.today)).to_a
      keys    = dates.map { |date| rdb_hits_date_key(type, date) }
      rdb_fetch_zunion(storkey, keys)
    end

    def combined_top_ids(days, weighted_types)
      types   = weighted_types.keys
      keys    = types.map { |type| rdb_stored_hits_union_key(type, days) }
      storkey = rdb_stored_weighted_hits_union_key(weighted_types, days)
      types.each { |type| top_ids(type, days) }
      rdb_fetch_zunion(storkey, keys, weights: weighted_types.values)
    end

    private

    def fetch_zunion(storekey, keys, opts = {})
      if rdb.zcard(storekey) == 0 # Not cached, or has expired
        rdb.zunionstore(storekey, keys, opts)
        rdb.expire(storekey, @config.expire)
      end
      rdb.zrevrange(storekey, 0, -1)
    end

    def warn(method)
      return if @config.enable_unique_tracking
      STDERR.puts("Warning: Tracker##{method} was called but unique tracking " \
      "is disabled.")
    end

    def store_windows(time, ns, thing, id, type, is_unique)
      WINDOWS.each do |window|
        ukey = @ks.hits_time_window_key("#{ns}.uniq", type, window, time)
        key  = @ks.hits_time_window_key(ns, type, window, time)
        secs = @config.send("#{window}_window_secs")
        if is_unique && @config.enable_unique_tracking
          rdb.zincrby(ukey, 1, id)
          rdb.expire(ukey, secs)
        end
        rdb.zincrby(key, 1, id)
        rdb.expire(key, secs)
      end
    end

    def rdb
      config.redis
    end

    def mk_object_id(obj)
      config.object_id_proc.(obj)
    end

    def mk_hit_member(uniquenesses, ensure_not_nil = false)
      if (obj = uniquenesses.flatten.reject { |u| Utils.blank?(u) }.first)
        @config.object_unique_hit_id_proc.(obj)
      elsif ensure_not_nil
        raise UniquenessError, "Unique criteria were not provided for the incoming hit."
      else
        Utils.quick_token
      end
    end

  end
end
