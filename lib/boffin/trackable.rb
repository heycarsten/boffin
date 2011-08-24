module Boffin
  module Trackable

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def boffin_tracker
        @boffin_tracker ||= Tracker.new(self)
      end

      def top_ids(type_or_weights, opts = {})
        boffin_tracker.top(type_or_weights, opts)
      end
    end

    def hit(type, uniquenesses = [])
      self.class.boffin_tracker.hit(type, self, uniquenesses)
    end

    def hit_count(type)
      self.class.boffin_tracker.hit_count(type, self)
    end

    def uhit_count(type)
      self.class.boffin_tracker.uhit_count(type, self)
    end

    def hit_count_for_session_id(type, sess_obj)
      self.class.boffin_tracker.hit_count_for_session_id(type, self, sess_obj)
    end

  end
end
