module Boffin
  module Trackable

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def boffin
        @boffin_tracker ||= Tracker.new(self)
      end

      def top_ids(type_or_weights, opts = {})
        boffin.top(type_or_weights, opts)
      end
    end

    def hit(type, uniquenesses = [])
      self.class.boffin.hit(type, self, uniquenesses)
    end

    def hit_count(type)
      self.class.boffin.hit_count(type, self)
    end

    def uhit_count(type)
      self.class.boffin.uhit_count(type, self)
    end

    def hit_count_for_session_id(type, sess_obj)
      self.class.boffin.hit_count_for_session_id(type, self, sess_obj)
    end

  end
end
