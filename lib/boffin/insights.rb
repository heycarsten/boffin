module Boffin
  module Insights

    def self.included(model)
      model.extend ClassMethods
    end

    module ClassMethods
      def rdb_keyspace
        "#{Boffin.redis_namespace}:#{Boffin::Utils.underscore(to_s)}"
      end

      def rdb_hits_keyspace(*types)
        "#{rdb_keyspace}.#{types.flatten.join('.')}.hits"
      end

      def rdb_stored_hits_union_key(type, days)
        "#{rdb_hits_keyspace(type)}:current.#{days}"
      end

      def rdb_stored_weighted_hits_union_key(weighted_types, days)
        types = weighted_types.map { |type, weight| "#{type}_#{weight}" }
        rdb_stored_hits_union_key(types, days)
      end

      def rdb_hits_date_key(type, date)
        "#{rdb_hits_keyspace(type)}:#{date.strftime('%F')}"
      end

      def rdb_instance_keyspace(type, id)
        "#{rdb_keyspace}:#{id}.#{type}"
      end

      def rdb_all_hits_key(type, id)
        "#{rdb_instance_keyspace(type, id)}.all_hits"
      end

      def rdb_all_hits_raw_count_key(type, id)
        "#{rdb_instance_keyspace(type, id)}.all_hits_raw_count"
      end

      def rdb_fetch_zunion(storekey, keys, opts = {})
        if Boffin.redis.zcard(storekey) == 0 # Not cached, or has expired
          Boffin.redis.zunionstore(storekey, keys, opts)
          Boffin.redis.expire(storekey, Boffin.expire)
        end
        Boffin.redis.zrevrange(storekey, 0, -1)
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
    end

    def rdb_all_hits_raw_count_key(type)
      self.class.rdb_all_hits_raw_count_key(type, id)
    end

    def rdb_all_hits_key(type)
      self.class.rdb_all_hits_key(type, id)
    end

    def rdb_today_hits_key(type)
      self.class.rdb_hits_date_key(type, Date.today)
    end

    # Called via controller action when an object is viewed.
    def hit(type, session_id, user = nil)
      member = (user ? "u:#{user.id}" : "s:#{session_id}")
      daykey = rdb_today_hits_key(type)
      Boffin.redis.incr(rdb_all_hits_raw_count_key(type))
      Boffin.redis.sadd(rdb_all_hits_key(type), member)
      Boffin.redis.zincrby(daykey, 1, id)
      Boffin.redis.expire(daykey, EXPIRE_DAILY_HITS_AFTER_SECS)
    end

    # Unique hits for the object
    def hit_count(type)
      Boffin.redis.scard(rdb_all_hits_key(type)).to_i
    end

    # Total raw hits for the object
    def raw_hit_count(type)
      Boffin.redis.get(rdb_all_hits_raw_count_key(type)).to_i
    end

  end
end
