module Boffin
  class Keyspace

    attr_reader :config

    def initialize(namespace, hit_types, config = Boffin.config.dup)
      @config = config
      @ns     = namespace
      @types  = [hit_types].flatten
    end

    def root(instance = nil, is_uniq = false)
      slug = instance ? object_as_key(instance) : nil
      "#{@config.namespace}:#{@ns}".tap { |s|
        s << ".uniq"    if is_uniq
        s << ".#{slug}" if slug }
    end

    def hits_key(is_uniq = false)
      "#{root(nil, is_uniq)}:#{@types.flatten.join('_')}:hits"
    end

    def hits_union_key(unit, size, is_uniq = false)
      "#{hits_key(is_uniq)}:current.#{unit}_#{size}"
    end

    def combi_hits_union_key(weighted_hit_types, unit, size, is_uniq = false)
      types = weighted_hit_types.map { |type, weight| "#{type}_#{weight}" }
      hits_union_key(unit, size, is_uniq)
    end

    def hits_window_key(window, is_uniq = false)
      "#{hits_key(is_uniq)}.#{window}"
    end

    def hits_time_window_key(unit, time, is_uniq = false)
      hits_window_key(time.strftime(WINDOW_UNIT_FORMATS[unit]), is_uniq)
    end

    def object_hits_key(instance, is_uniq = false)
      "#{root(instance, is_uniq)}.hits"
    end

    def object_hit_count_key(instance)
      "#{root(instance, is_uniq)}.hit_count"
    end

    protected

    def object_as_key(obj)
      if obj.respond_to?(:id)
        obj.id.to_s
      else
        Base64.strict_encode64(obj.to_s)
      end
    end

  end
end
