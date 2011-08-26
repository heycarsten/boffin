module Boffin
  # Stores configuration state to be used in various parts of the app. You will
  # likely not need to instantiate Config directly.
  class Config

    attr_writer \
      :redis,
      :namespace,
      :hours_window_secs,
      :days_window_secs,
      :months_window_secs,
      :cache_expire_secs

    # @param [Hash] opts
    #   The parameters to create a new Config instance
    # @option opts [Redis] :redis
    # @option opts [String] :namespace
    # @option opts [Fixnum] :hours_window_secs
    # @option opts [Fixnum] :days_window_secs
    # @option opts [Fixnum] :months_window_secs
    # @option opts [Fixnum] :cache_expire_secs
    # @yield [self]
    def initialize(opts = {}, &block)
      yield(self) if block_given?
      update(opts)
    end

    # Updates self with the values provided
    # @param [Hash] updates
    #   A hash of options to update the config instance with
    # @return [self]
    def update(updates = {})
      tap do |conf|
        updates.each_pair { |k, v| conf.send(:"#{k}=", v) }
      end
    end

    # Creates a copy of self and updates the copy with the values provided
    # @param [Hash] updates
    #   A hash of options to merge with the instance
    # @return [Config] the new Config instance with updated values
    def merge(updates = {})
      dup.update(updates)
    end

    # The Redis instance that will be used to store hit data
    # @return [Redis] the active Redis connection
    def redis
      @redis ||= Redis.connect
    end

    # The namespace to prefix all Redis keys with. Defaults to `"boffin"` or
    # `"boffin:<env>"` if `RACK_ENV` or `RAILS_ENV` are present in the
    # environment.
    # @return [String]
    def namespace
      @namespace ||= begin
        if (env = ENV['RACK_ENV'] || ENV['RAILS_ENV'])
          "boffin:#{env}"
        else
          "boffin"
        end
      end
    end

    # @return [Fixnum]
    #   Number of seconds to maintain the hourly hit interval window
    def hours_window_secs
      @hours_window_secs ||= 3 * 24 * 3600 # 3 days
    end

    # @return [Fixnum]
    #   Number of seconds to maintain the daily hit interval window
    def days_window_secs
      @days_window_secs ||= 3 * 30 * 24 * 3600 # 3 months
    end

    # @return [Fixnum]
    #   Number of seconds to maintain the monthly hit interval window
    def months_window_secs
      @months_window_secs ||= 3 * 12 * 30 * 24 * 3600 # 3 years
    end

    # @return [Fixnum]
    #   Number of seconds to cache the results of `Tracker.top`
    def cache_expire_secs
      @cache_expire_secs ||= 15 * 60 # 15 minutes
    end

  end
end
