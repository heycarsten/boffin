module Boffin
  class Config

    attr_writer \
      :redis,
      :namespace,
      :disable_unique_tracking,
      :hours_window_secs,
      :days_window_secs,
      :months_window_secs,
      :cache_expire_secs,
      :object_as_key_proc,
      :object_as_member_proc,
      :object_as_unique_member_proc

    def initialize(&block)
      yield(self) if block_given?
      self
    end

    def merge(updates = {})
      dup.tap do |conf|
        updates.each_pair { |k, v| conf.send(:"#{k}=", v) }
      end
    end

    def redis
      @redis ||= Redis.connect
    end

    def namespace
      @namespace ||= begin
        if (env = ENV['RACK_ENV'] = ENV['RAILS_ENV'])
          "boffin:#{env}"
        else
          "boffin"
        end
      end
    end

    def disable_unique_tracking
      @disable_unique_tracking ||= false
    end

    def hours_window_secs
      @hours_window_secs ||= 24 * 3600 # 1 day
    end

    def days_window_secs
      @days_window_secs ||= 30 * 24 * 3600 # 1 month
    end

    def months_window_secs
      @months_window_secs ||= 12 * 30 * 24 * 3600 # 1 year
    end

    def cache_expire_secs
      @cache_expire_secs ||= 3600 # 1 hour
    end

    def object_as_member_proc
      @object_as_member_proc ||= lambda { |obj|
        case
        when obj.respond_to?(:id)
          obj.id.to_s
        when obj.respond_to?(:as_member)
          obj.as_member.to_s
        else
          obj.to_s
        end
      }
    end

  end
end
