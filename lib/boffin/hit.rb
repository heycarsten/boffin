module Boffin
  class Hit

    attr_reader :config, :tracker, :ns, :type

    def initialize(tracker, namespace, type, instance, uniquenesses = [])
      @now      = Time.now
      @tracker  = tracker
      @config   = @tracker.config
      @ns       = namespace
      @type     = type
      @instance = instance
      @member   = object_as_member(@instance)
      @sessid   = uniquenesses_as_uniqueness_identifier(uniquenesses)
      @opts     = opts
      @keyspace = Keyspace.new(@ns, @type, @config)
      @exp_secs = @config.send("#{window}_window_secs")
      store
    end

    def store
      if track_hit
        # Never tracked before by this session
        set_windows(true)
      else
        set_windows(false)
      end
    end

    def track_hit
      rdb.incr(@keyspace.hit_count_key)
      rdb.zincrby(@keyspace.object_hits_key(@instance), 1, @sessid).to_i == 1
    end

    def set_windows(is_unique)
      WINDOW_UNIT_TYPES.each do |window|
        set_window(window, true) if is_unique
        set_window(window)
      end
    end

    def set_window(window, is_unique = false)
      key = @keyspace.hits_time_window_key(window, @now, is_unique)
      rdb.zincrby(key, 1, @member)
      rdb.expire(key, @exp_secs)
    end

    def hit_count(ns, thing, type)
      key = object_as_key(thing)
      rdb.get(@ks.object_hit_count_key(ns, key, type)).to_i
    end

    def uniq_hit_count(ns, thing, type)
      key = object_as_key(thing)
      rdb.scard(@ks.object_hits_key(ns, key, type)).to_i
    end

    def top(ns, type, params = {})
      unit, size = *Utils.extract_time_unit(params)
      storkey    = @ks.hits_union_key(ns, type, unit, size)
      keys       = window_keys(ns, type, unit, size)
      fetch_zunion(storkey, keys, params)
    end

    def utop(ns, type, params = {})
      warn('utop')
      top("#{ns}.uniq", params)
    end

    def trending(ns, params = {})
      unit, size = *Utils.extract_time_unit(params)
      hit_types  = weights.keys
      weights    = params[:weights]
      keys       = hit_types.map { |t| window_keys(ns, type, unit, t) }
      storkey    = @ks.combi_hits_union_key(ns, weights, unit, size)
      opts       = { weights: weights.values }.merge(params)
      types.each { top(ns, type, params) }
      fetch_zunion(storkey, keys, opts)
    end

    def utrending(ns, params = {})
      warn('utrending')
      trending("#{ns}.uniq", params)
    end

    private

    def rdb
      @config.redis
    end

    def window_keys(unit, size)
      Utils.time_ago_range(Time.now, unit => size).
        map { |t| hits_time_window_key(unit, t) }
    end

    def object_as_member(obj)
      @config.object_as_member_proc.(obj)
    end

    def uniquenesses_as_uniqueness_identifier(aspects)
      if (obj = aspects.flatten.reject { |u| Utils.blank?(u) }.first)
        if obj.respond_to?(:id)
          "#{Utils.underscore(obj.class)}:#{obj.id}"
        else
          obj.to_s
        end
      else
        Utils.quick_token
      end
    end

    def fetch_zunion(storekey, keys, opts = {})
      zrangeopts = {
        counts: opts.delete(:counts),
        order:  (opts.delete(:order) || :desc).to_sym }
      if rdb.zcard(storekey) == 0 # Not cached, or has expired
        rdb.zunionstore(storekey, keys, opts)
        rdb.expire(storekey, @config.cache_expire_secs)
      end
      zrange(storekey, zrangeopts)
    end

    def zrange(key, opts)
      cmdopt = opts[:counts] ? { withscores: true } : {}
      args   = [key, 0, -1, cmdopt]
      result = case opts[:order]
        when :asc  then rdb.zrange(*args)
        when :desc then rdb.zrevrange(*args)
      end
      if opts[:counts]
        result.each_slice(2).map { |mbr, score| [mbr, score.to_i] }
      else
        result
      end
    end

    def warn(method)
      return if @config.enable_unique_tracking
      STDERR.puts("Warning: Tracker##{method} was called but unique tracking " \
      "is disabled.")
    end

  end
end
