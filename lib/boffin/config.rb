module Boffin
  class Config

    attr_writer \
      :redis,
      :namespace,
      :disable_unique_tracking,
      :hours_window_secs,
      :days_window_secs,
      :months_window_secs,
      :cache_expire_secs

    def initialize(opts = {}, &block)
      yield(self) if block_given?
      update(opts)
      self
    end

    def update(updates = {})
      tap do |conf|
        updates.each_pair { |k, v| conf.send(:"#{k}=", v) }
      end
    end

    def merge(updates = {})
      dup.update(updates)
    end

    def redis
      @redis ||= Redis.connect
    end

    def namespace
      @namespace ||= begin
        if (env = ENV['RACK_ENV'] || ENV['RAILS_ENV'])
          "boffin:#{env}"
        else
          "boffin"
        end
      end
    end

    def hours_window_secs
      @hours_window_secs ||= 3 * 24 * 3600 # 3 days
    end

    def days_window_secs
      @days_window_secs ||= 3 * 30 * 24 * 3600 # 3 months
    end

    def months_window_secs
      @months_window_secs ||= 3 * 12 * 30 * 24 * 3600 # 3 years
    end

    def cache_expire_secs
      @cache_expire_secs ||= 15 * 60 # 15 minutes
    end

  end
end
