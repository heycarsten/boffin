module Boffin
  class Tracker

    attr_reader :namespace, :config
    attr_accessor :hit_types

    # @param [String, Symbol, #to_s] class_or_ns
    #   A string, symbol or any object that responds to `#to_s` that will be
    #   used to namespace this keys of this Tracker.
    # @param [Array<Symbol>] hit_types
    #   A list of hit types that this Tracker will allow, if empty then any
    #   hit type will be allowed.
    # @param [Config] config
    #   A Config instance to use instead of Boffin.config
    # @example
    #   Tracker.new(MyModel, [:views, likes])
    #   Tracker.new(:urls,   [:shares, :clicks])
    def initialize(class_or_ns, hit_types = [], config = Boffin.config.dup)
      @namespace = Utils.object_as_namespace(class_or_ns)
      @hit_types = hit_types
      @config    = config
      @keyspace  = Keyspace.new(self)
      @ukeyspace = Keyspace.new(self, true)
    end

    # @param [Symbol] hit_type
    # @param [#as_member, #id, #to_s] instance
    # @param [Hash] options
    # @option options [Array] :unique ([]) uniquenesses
    # @option options [Fixnum] :increment (1) hit increment
    # @return [Hit]
    # @raise Boffin::UndefinedHitTypeError
    #   Raised if a list of hit types is available and the provided hit type is
    #   not in the list.
    def hit(hit_type, instance, opts = {})
      validate_hit_type(hit_type)
      Hit.new(self, hit_type, instance, opts)
    end

    # @param [Symbol] hit_type
    # @param [#as_member, #id, #to_s] instance
    # @return [Fixnum]
    # @raise Boffin::UndefinedHitTypeError
    #   Raised if a list of hit types is available and the provided hit type is
    #   not in the list.
    def hit_count(hit_type, instance)
      validate_hit_type(hit_type)
      redis.get(keyspace.hit_count(hit_type, instance)).to_i
    end

    # @param [Symbol] hit_type
    # @param [#as_member, #id, #to_s] instance
    # @return [Fixnum]
    # @raise Boffin::UndefinedHitTypeError
    #   Raised if a list of hit types is available and the provided hit type is
    #   not in the list.
    def uhit_count(hit_type, instance)
      validate_hit_type(hit_type)
      redis.zcard(keyspace.hits(hit_type, instance)).to_i
    end

    # @param [Symbol] hit_type
    # @param [#as_member, #id, #to_s] instance
    # @param [#as_member, #id, #to_s] sess_obj
    # @return [Fixnum]
    # @raise Boffin::UndefinedHitTypeError
    #   Raised if a list of hit types is available and the provided hit type is
    #   not in the list.
    def hit_count_for_session_id(hit_type, instance, sess_obj)
      validate_hit_type(hit_type)
      sessid = Utils.object_as_session_identifier(sess_obj)
      redis.zscore(keyspace.hits(hit_type, instance), sessid).to_i
    end

    # Performs set union across the specified number of hours, days, or months
    # to calculate the members with the highest hit counts. The operation can
    # be performed on one hit type, or multiple hit types with weights.
    # @param [Symbol, Hash] type_or_weights
    #   When Hash the set union is calculated 
    # @param [Hash] opts
    # @option opts [true, false] :unique (false)
    #   If `true` then only unique hits are considered in the calculation
    # @option opts [true, false] :counts (false)
    #   If `true` then scores are returned along with the top members
    # @option opts [:desc, :asc] :order (:desc)
    #   The order of the results, in decending (most hits to least hits) or
    #   ascending (least hits to most hits) order.
    # @option opts [Fixnum] :hours
    #   Perform union for hit counts over the last _n_ hours.
    # @option opts [Fixnum] :days
    #   Perform union for hit counts over the last _n_ days.
    # @option opts [Fixnum] :months
    #   Perform union for hit counts over the last _n_ months.
    # @example Return IDs of most viewed and liked listings in the past 6 days with scores
    #   @tracker.top({ views: 1, likes: 1 }, counts: true, days: 6)
    # @example Return IDS of most viewed and liked listings in the past 6 days with scores (Alternate syntax)
    #   @tracker.top([[:views, 1], [:likes, 1]], counts: true, days: 6)
    # @example Return IDs of most viewed listings in the past 12 hours
    #   @tracker.top(:views, hours: 12)
    # @note
    #   The result set returned is cached in Redis for the duration of
    #   {Config#cache_expire_secs}
    # @note
    #   Only one of `:hours`, `:days`, or `:months` should be specified in the
    #   options hash as they can not be combined.
    # @raise Boffin::UndefinedHitTypeError
    #   If a list of hit types is available and any of the provided hit types is
    #   not in the list.
    def top(type_or_weights, opts = {})
      validate_hit_type(type_or_weights)
      unit, size = *Utils.extract_time_unit(opts)
      keyspace   = keyspace(opts[:unique])
      if type_or_weights.is_a?(Hash)
        multiunion(keyspace, type_or_weights, unit, size, opts)
      else
        union(keyspace, type_or_weights, unit, size, opts)
      end
    end

    # @param [true, false] uniq
    #   If `true` the unique-scoped keyspace is returned
    # @return [Keyspace]
    #   Keyspace associated with this tracker
    def keyspace(uniq = false)
      uniq ? @ukeyspace : @keyspace
    end

    # @return [Redis] The Redis connection for this Tracker's config
    def redis
      @config.redis
    end

    private

    # Checks to see if `hit_type` exists in the list of hit types. If no
    # elements exist in @hit_types then the check is skipped.
    # @param [Symbol] hit_type
    # @raise Boffin::UndefinedHitTypeError
    #   Raised if a list of hit types is available and the provided hit type is
    #   not in the list.
    def validate_hit_type(hit_type)
      return if @hit_types.empty?
      (hit_type.is_a?(Hash) ? hit_type.keys : [hit_type]).each do |type|
        next if @hit_types.include?(type)
        raise UndefinedHitTypeError, "#{type} is not in the list of " \
        "valid hit types for this Tracker, valid types are: " \
        "#{@hit_types.inspect}"
      end
    end

    # @param [Keyspace] ks
    #   Keyspace to perform the union on
    # @param [Symbol] hit_type
    # @param [:hours, :days, :months] unit
    # @param [Fixnum] size
    #   Number of intervals to include in the union
    # @param [Hash] opts
    # @option opts [true, false] :counts (false)
    # @option opts [:asc, :desc] :order (:desc)
    # @return [Array<String>, Array<Array>]
    # @see #zfetch
    def union(ks, hit_type, unit, size, opts = {})
      keys = ks.hit_time_windows(hit_type, unit, size)
      zfetch(ks.hits_union(hit_type, unit, size), keys, opts)
    end

    # Performs {#union} for each hit type, then performs a union on those
    # result sets with the provided weights.
    # @param [Keyspace] ks
    #   Keyspace to perform the union on
    # @param [Hash] weights
    # @param [Symbol] hit_type
    # @param [:hours, :days, :months] unit
    # @param [Fixnum] size
    #   Number of intervals to include in the union
    # @param [Hash] opts
    # @option opts [true, false] :counts (false)
    # @option opts [:asc, :desc] :order (:desc)
    # @return [Array<String>, Array<Array>]
    # @see #zfetch
    def multiunion(ks, weights, unit, size, opts = {})
      weights.keys.each { |t| union(ks, t, unit, size, opts) }
      keys = weights.keys.map { |t| ks.hits_union(t, unit, size) }
      zfetch(ks.hits_union_multi(weights, unit, size), keys, {
        :weights => weights.values
      }.merge(opts))
    end

    # Checks to see if the result set exists (is cached), if it does the set is
    # returned, otherwise a union of the keys is performed, cached, and
    # returned.
    # @param [String] storkey
    #   Key to store the result set under
    # @param [Array<String>] keys
    # @param [Hash] opts
    # @option opts [true, false] :counts (false)
    # @option opts [:asc, :desc] :order (:desc)
    # @see #zrange
    def zfetch(storkey, keys, opts = {})
      zrangeopts = {
        :counts => opts.delete(:counts),
        :order  => (opts.delete(:order) || :desc).to_sym }
      if redis.zcard(storkey) == 0
        redis.zunionstore(storkey, keys, opts)
        redis.expire(storkey, @config.cache_expire_secs)
      end
      zrange(storkey, zrangeopts)
    end

    # Performs a range on a sorted set at key.
    # @param [String] key
    # @param [Hash] opts
    # @option opts [true, false] :counts (false)
    # @option opts [:asc, :desc] :order (:desc)
    # @return [Array<String>, Array<Array>]
    #   Returns an array of members in sorted order, optionally if the `:counts`
    #   option is `true` it returns an array of pairs where the first value is
    #   the member, and the second value is the member's score.
    def zrange(key, opts)
      args = [key, 0, -1, opts[:counts] ? { :withscores => true } : {}]
      result = case opts[:order]
        when :asc  then redis.zrange(*args)
        when :desc then redis.zrevrange(*args)
      end
      if opts[:counts]
        result.each_slice(2).map { |mbr, score| [mbr, score.to_i] }
      else
        result
      end
    end

  end
end
