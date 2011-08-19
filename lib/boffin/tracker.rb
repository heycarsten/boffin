module Boffin
  class Tracker
    def initialize(config = Config.new)
      @config = config
      @keyspace = Keyspace.new(config)
    end

    def hit(ns, thing, type, *uniquenesses, opts)
      opts ||= {}
      member = mk_hit_member(uniquenesses, opts[:unique])
      daykey = rdb_today_hits_key(type)
      id     = mk_object_id(object)
      rdb.incr(rdb_all_hits_raw_count_key(type))
      rdb.sadd(rdb_all_hits_key(type), member)
      rdb.zincrby(daykey, 1, id)
      rdb.expire(daykey, @config.daily_expire_secs)
    end

    def uhit(namespace, instance, hitspace, *uniquenesses)
      hit(namespace, instance, hitspace, *uniquenesses, unique: true)
    end

    def unique_hit_count(namespace, hitspace)
    end

    def hit_count(namespace, hitspace)
    end

    def top(days, namespace, hitspace)
    end

    def trending(days, namespace, weighted_hitspaces)
    end

    def rdb_fetch_zunion(storekey, keys, opts = {})
      if rdb.zcard(storekey) == 0 # Not cached, or has expired
        rdb.zunionstore(storekey, keys, opts)
        rdb.expire(storekey, @config.expire)
      end
      rdb.zrevrange(storekey, 0, -1)
    end

    # Returns ids of the top objects in the specified set (type) in the past n
    # days. I drop down to the raw Redis client (not the wrapped one for
    # namespaces) as it is currently not implemented for zunionstore.
    def top_ids(type, days = 7)
      storkey = rdb_stored_hits_union_key(type, days)
      dates   = (((days-1).days.ago.to_date)..(Date.today)).to_a
      keys    = dates.map { |date| rdb_hits_date_key(type, date) }
      rdb_fetch_zunion(storkey, keys)
    end

    # Returns ids of the top objects for the types specified
    # all_top_ids(7, views: 1, joins: 2, votes: 3)
    def combined_top_ids(days, weighted_types)
      types   = weighted_types.keys
      keys    = types.map { |type| rdb_stored_hits_union_key(type, days) }
      storkey = rdb_stored_weighted_hits_union_key(weighted_types, days)
      types.each { |type| top_ids(type, days) }
      rdb_fetch_zunion(storkey, keys, weights: weighted_types.values)
    end

    private

    def rdb
      @config.redis
    end

    def mk_object_id(obj)
      @config.object_id_proc.(obj)
    end

    def mk_hit_member(uniquenesses, ensure_not_nil = false)
      if (obj = uniquenesses.flatten.reject { |u| Utils.blank?(u) }.first)
        @config.object_unique_hit_id_proc.(obj)
      elsif ensure_not_nil
        raise WithoutUniquenessError, "No unique objects were provided"
      else
        Utils.quick_token
      end
    end

  end
end
