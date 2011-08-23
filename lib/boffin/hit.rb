module Boffin
  class Hit

    def initialize(tracker, type, instance, uniquenesses = [])
      @now      = Time.now
      @sessid   = Utils.uniquenesses_as_session_identifier(uniquenesses)
      @type     = type
      @tracker  = tracker
      @instance = instance
      @member   = @tracker.object_as_member(@instance)
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
      WINDOW_UNIT_TYPES.each do |interval|
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
