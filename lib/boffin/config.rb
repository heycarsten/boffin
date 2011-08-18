module Boffin
  class Config

    attr_writer \
      :redis,
      :namespace,
      :hourly_expire_secs,
      :daily_expire_secs,
      :monthly_expire_secs,
      :cache_expire_secs,
      :object_id_proc,
      :object_unique_hit_id

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

    def hourly_expire_secs
      @hourly_expire_secs ||= 24 * 3600 # 1 day
    end

    def daily_expire_secs
      @daily_expire_secs ||= 30 * 24 * 3600 # 1 month
    end

    def monthly_expire_secs
      @monthly_expire_secs ||= 12 * 30 * 24 * 3600 # 1 year
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

    def object_unique_hit_id_proc
      @hit_unique_id_proc ||= lambda { |obj|
        if obj.respond_to?(:boffin_unique_hit_id)
          obj.boffin_unique_hit_id
        else
          "#{Utils.underscore(obj.class)}:#{obj.id}"
        end
      }
    end

  end
end
