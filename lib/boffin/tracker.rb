module Boffin
  class Tracker

    attr_reader :config, :ks

    def initialize(config = Boffin.config.dup)
      @config = config
      @ks = Keyspace.new(@config)
    end

    def hit(ns, thing, type, uniquenesses = [], opts = {})
      now    = Time.now
      member = uniquenesses_as_unique_member(uniquenesses, opts[:unique])
      id     = mk_object_id(thing)
      rdb.incr(@ks.object_hit_count_key(ns, id, type))
      if rdb.sadd(@ks.object_hits_key(ns, id, type), member)
        store_windows(now, ns, thing, id, type, true)
      else
        store_windows(now, ns, thing, id, type, false)
      end
    end

    def uhit(ns, thing, type, uniquenesses = [])
      hit(ns, thing, type, uniquenesses, unique: true)
    end

    def hit_count(ns, thing, type)
      id = mk_object_id(thing)
      rdb.get(@ks.object_hit_count_key(ns, id, type)).to_i
    end

    def uhit_count(ns, thing, type)
      id = mk_object_id(thing)
      rdb.scard(@ks.object_hits_key(ns, id, type)).to_i
    end

    def top(ns, type, params = {})
      unit, size = Utils.extract_time_unit(params)
      window     = window_range(unit, size)
      storkey    = @ks.hits_union_key(ns, type, unit, size)
      keys       = window_keys(ns, type, unit, size)
      fetch_zunion(storkey, keys)
    end

    def utop(ns, type, params = {})
      warn('utop')
      top("#{ns}.uniq", params)
    end

    def trending(ns, params = {})
      unit, size = Utils.extract_time_unit(params)
      window     = window_range(unit, size)
      types      = weights.keys
      weights    = params[:weights]
      keys       = types.map { |t| window_keys(ns, type, unit, t) }
      storkey    = @ks.combi_hits_union_key(ns, weights, unit, size)
      types.each { top(ns, type, params) }
      fetch_zunion(storkey, keys, weights: weights.values)
    end

    def utrending(ns, params = {})
      warn('utrending')
      trending("#{ns}.uniq", params)
    end

    private

    def window_keys(ns, type, unit, size)
      Utils.time_ago_range(Time.now, unit => size).
        map { |t| @ks.hits_time_window_key(ns, type, unit, t) }
    end

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
      WINDOW_UNIT_TYPES.each do |window|
        ukey = @ks.hits_time_window_key("#{ns}.uniq", type, window, time)
        key  = @ks.hits_time_window_key(ns, type, window, time)
        secs = @config.send("#{window}_window_secs")
        if is_unique && !@config.disable_unique_tracking
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

    def uniquenesses_as_unique_member(uniquenesses, ensure_not_nil = false)
      if (obj = uniquenesses.flatten.reject { |u| Utils.blank?(u) }.first)
        @config.object_as_unique_member_proc.(obj)
      elsif ensure_not_nil
        raise NoUniquenessError, 'Unique criteria not provided for the ' \
        'incoming hit.'
      else
        Utils.quick_token
      end
    end

  end
end
