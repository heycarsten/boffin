module Boffin
  module Utils

    module_function

    # Yoinked from ActiveSupport::Inflector
    def underscore(mod)
      word = mod.to_s.dup
      word.gsub!(/::/, '_')
      word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.tr!('-', '_')
      word.downcase!
      word
    end

    def blank?(obj)
      obj.respond_to?(:empty?) ? obj.empty? : !obj
    end

    def quick_token(seed = 0x100000)
      3.times.map { rand(seed).to_s(36) }.join
    end

  end
end
