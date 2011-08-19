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
      :object_id_proc,
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

    def object_id_proc
      @object_id_proc ||= lambda { |obj|
        if obj.respond_to?(:id)
          obj.id.to_s
        else
          Base64.strict_encode64(obj.to_s)
        end
      }
    end

    def object_as_unique_member_proc
      @object_as_unique_member_proc ||= lambda { |obj|
        case
        when obj.respond_to?(:as_unique_member)
          obj.as_unique_member
        when obj.is_a?(String), obj.is_a?(Symbol), obj.is_a?(Numeric)
          obj.to_s
        else
          "#{Utils.underscore(obj.class)}:#{obj.id}"
        end
      }
    end

  end
end
