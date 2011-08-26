module Boffin
  # Represents a Hit instance, immutable once created. Interacting with Hit
  # directly is not necessary.
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
    # @param [Array] uniquenesses
    #   An array of which the first object is used to generate a session
    #   identifier for hit uniqueness
    def initialize(tracker, type, instance, uniquenesses = [])
      @now      = Time.now
      @sessid   = Utils.uniquenesses_as_session_identifier(uniquenesses)
      @type     = type
      @tracker  = tracker
      @instance = instance
      @member   = Utils.object_as_member(@instance)
      store
      freeze
    end

    private

    def redis
      @tracker.redis
    end

    def keyspace(*args)
      @tracker.keyspace(*args)
    end

    def store
      if track_hit
        set_windows(true)
      else
        set_windows(false)
      end
    end

    def track_hit
      redis.incr(keyspace.hit_count(@type, @instance))
      redis.zincrby(keyspace.hits(@type, @instance), 1, @sessid) == '1'
    end

    def set_windows(uniq)
      INTERVAL_TYPES.each do |interval|
        set_window_interval(interval, true) if uniq
        set_window_interval(interval)
      end
    end

    def set_window_interval(interval, uniq = false)
      key = keyspace(uniq).hits_time_window(@type, interval, @now)
      redis.zincrby(key, 1, @member)
      redis.expire(key, @tracker.config.send("#{interval}_window_secs"))
    end

  end
end
