module Boffin
  module Trackable

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def boffin
        @boffin ||= Tracker.new(self)
      end

      def top_ids(hit_type, opts = {})
        boffin.top(hit_type, opts)
      end

      def trending_ids(weighted_types, opts = {})
        boffin.trending(weighted_types, opts)
      end
    end

    def hits_by_session_id(sessid)
      self.class.boffin.hits_by_session_id(self, sessid)
    end

    def hit_count(hit_type)
      self.class.boffin.hit_count(self, hit_type)
    end

    def unique_hit_count(hit_type)
      self.class.boffin.unique_hit_count(self, hit_type)
    end

  end
end