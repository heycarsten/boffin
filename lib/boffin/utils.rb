module Boffin::Utils

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

end
