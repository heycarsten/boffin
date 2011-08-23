module Boffin
  class Tracker

    attr_reader :namespace, :hit_types, :config

    def initialize(class_or_ns, hit_types = [], config = Boffin.config.dup)
      @namespace = Utils.object_as_namespace(class_or_ns)
      @hit_types = hit_types
      @config    = config
      @keyspace  = Keyspace.new(self)
      @ukeyspace = Keyspace.new(self, true)
    end

    def hit(hit_type, instance, uniquenesses = [])
      Hit.new(self, hit_type, instance, uniquenesses)
    end

    def hit_count(hit_type, instance)
      redis.get(keyspace.hit_count(hit_type, instance))
    end

    def uhit_count(hit_type, instance)
      redis.zcard(keyspace.hits(hit_type, instance)).to_i
    end

    def hit_count_for_session_id(hit_type, instance, sess_obj)
      sessid = Utils.object_as_session_identifier(sess_obj)
      redis.zscore(keyspace.hits(hit_type, instance), sessid).to_i
    end

    def top(type_or_weights, opts = {})
      unit, size = *Utils.extract_time_unit(opts)
      keyspace   = keyspace(opts[:unique])
      if type_or_weights.is_a?(Hash)
        multiunion(keyspace, type_or_weights, unit, size, opts)
      else
        union(keyspace, type_or_weights, unit, size, opts)
      end
    end

    def utop(type_or_weights, opts = {})
      opts[:unique] = true
      top(type_or_weights, opts)
    end

    def object_as_member(obj)
      @config.object_as_member_proc.(obj)
    end

    def redis
      @config.redis
    end

    def keyspace(uniq = false)
      uniq ? @ukeyspace : @keyspace
    end

    private

    def union(keyspace, type, unit, size, opts = {})
      keys = keyspace.hit_time_windows(type, unit, size)
      zfetch(keyspace.hits_union(type, unit, size), keys, opts)
      keys
    end

    def multiunion(keyspace, weights, unit, size, opts = {})
      keys = weights.keys.map { |type| union(keyspace, type, unit, size, opts) }
      zfetch(keyspace.hits_union_multi(weights, unit, size), keys, {
        weights: weights.values
      }.merge(opts))
    end

    def zfetch(storkey, keys, opts = {})
      zrangeopts = {
        counts: opts.delete(:counts),
        order:  (opts.delete(:order) || :desc).to_sym }
      if redis.zcard(storekey) == 0
        redis.zunionstore(storkey, keys, opts)
        redis.expire(storkey, @config.cache_expire_secs)
      end
      zrange(storkey, zrangeopts)
    end

    def zrange(key, opts)
      args = [key, 0, -1, opts[:counts] ? { withscores: true } : {}]
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

  end
end
