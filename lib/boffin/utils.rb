module Boffin
  module Utils

    SECONDS_IN_HOUR  = 3600
    SECONDS_IN_DAY   = 24 * SECONDS_IN_HOUR
    SECONDS_IN_MONTH = 30 * SECONDS_IN_DAY
    SECONDS_IN_UNIT  = {
      hours:  SECONDS_IN_HOUR,
      days:   SECONDS_IN_DAY,
      months: SECONDS_IN_MONTH
    }

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

    def extract_time_unit(hsh)
      case
      when hsh.key?(:hours)  then [:hours,  hsh[:hours]]
      when hsh.key?(:days)   then [:days,   hsh[:days]]
      when hsh.key?(:months) then [:months, hsh[:months]]
      else
        raise ArgumentError, 'no time unit exists in the hash provided'
      end
    end

    def time_ago(time, unit)
      unit, unit_value = *extract_time_unit(unit)
      time - (unit_value * SECONDS_IN_UNIT[unit])
    end

    def time_ago_range(upto, unit)
      unit, size = *extract_time_unit(unit)
      ago = time_ago(upto, unit => (size - 1))
      max, count, times = upto.to_i, ago.to_i, []
      begin
        times << Time.at(count)
      end while (count += SECONDS_IN_UNIT[unit]) <= max
      times
    end

  end
end
