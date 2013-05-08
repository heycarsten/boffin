module Boffin
  # Represents a Hit instance, immutable once created. Interacting with and
  # instantiating Hit directly is not necessary.
  class Hit

    # Creates a new Hit instance
    #
    # @param [Tracker] tracker
    #   Tracker that is issuing the hit
    # @param [Symbol] type
    #   Hit type identifier
    # @param [Object] instance
    #   The instance that is being hit, any object that responds to
    #   `#to_member`, `#id`, or `#to_s`
    # @param [Hash] opts
    # @option opts [Array] :unique ([]) An array of which the first
    #   object is used to generate a session identifier for hit uniqueness
    # @option opts [Fixnum] :increment (1) The hit increment
    def initialize(tracker, type, instance, opts = {})
      uniquenesses = opts.delete(:unique) || []
      @increment   = opts.delete(:increment) || 1
      @now         = Time.now
      @sessid      = Utils.uniquenesses_as_session_identifier(uniquenesses)
      @type        = type
      @tracker     = tracker
      @instance    = instance
      @member      = Utils.object_as_member(@instance)
      store
      freeze
    end

    private

    # @return [Redis]
    def redis
      @tracker.redis
    end

    # @return [Keyspace]
    def keyspace(*args)
      @tracker.keyspace(*args)
    end

    # Stores the hit data in each time window interval key for the current time.
    # If the hit is unique, also add the data to the keys in the unique keyspace.
    def store
      if track_hit
        set_windows(true)
      else
        set_windows(false)
      end
    end

    # Increments the {Keyspace#hit_count} key and adds the session member to
    # {Keyspace#hits}.
    # @return [true, false]
    #   `true` if this hit is unique, `false` if it has been made before by the
    #   same session identifer.
    def track_hit
      redis.incrbyfloat(keyspace.hit_count(@type, @instance), @increment)
      redis.zincrby(keyspace.hits(@type, @instance), 1, @sessid) == 1.0
    end

    # Store the hit member across all time intervals for the current window
    # @param [true, false] uniq
    #   If `true` the hit is also added to the keys scoped for unique hits
    def set_windows(uniq)
      INTERVAL_TYPES.each do |interval|
        set_window_interval(interval, true) if uniq
        set_window_interval(interval)
      end
    end

    # Increments in the instance member in the sorted set under
    # {Keyspace#hits_time_window}.
    # @param [:hours, :days, :months] interval
    # @param [true, false] uniq
    #   Changes keyspace scope to keys under .uniq
    def set_window_interval(interval, uniq = false)
      key = keyspace(uniq).hits_time_window(@type, interval, @now)
      redis.zincrby(key, @increment, @member)
      redis.expire(key, @tracker.config.send("#{interval}_window_secs"))
    end

  end
end
