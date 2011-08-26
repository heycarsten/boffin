module Boffin
  # A collection of utility methods that are used throughout the library
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

    # @param [Object #to_s] thing
    #   A Module, Class, String, or anything in which the underscored value of
    #   `#to_s` is desirable.
    # @return [String]
    #   The underscored version of `#to_s` on thing
    # @note
    #   Originally pulled from ActiveSupport::Inflector
    def underscore(thing)
      thing.to_s.dup.tap do |word|
        word.gsub!(/::/, '_')
        word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
        word.tr!('-', '_')
        word.downcase!
      end
    end

    # @param [Object] obj any Ruby object
    # @return [true, false]
    #   `true` if the provided object is blank, examples of blank objects are:
    #   `[]`, `{}`, `nil`, `false`, `''`.
    def blank?(obj)
      obj.respond_to?(:empty?) ? obj.empty? : !obj
    end

    # Pulls time interval information from a hash of options.
    # @example
    #   extract_time_unit(this: 'is ignored', days: 6, so_is: 'this')
    #   #=> [:days, 6]
    # @param [Hash] hsh
    #   Any Hash that contains amoungst its keys one of `:hours`, `:days`, or
    #   `:months`.
    # @return [Array]
    #   A two-element array containing the unit-type (`:hours`, `:days`, or
    #   `:months`) and the value.
    def extract_time_unit(hsh)
      case
      when hsh.key?(:hours)  then [:hours,  hsh[:hours]]
      when hsh.key?(:days)   then [:days,   hsh[:days]]
      when hsh.key?(:months) then [:months, hsh[:months]]
      else
        raise ArgumentError, 'no time unit exists in the hash provided'
      end
    end

    # Returns a time in the past by a specified offset
    # @example
    #   time_ago(Time.local(2011, 1, 3), days: 2)
    #   #=> 2011-01-01 00:00:00
    # @param [Time] time
    #   The initial time that the offset will be calculated from
    # @param [Hash] unit
    #   (see #extract_time_unit)
    # @return [Time]
    #   The time in the past
    def time_ago(time, unit)
      unit, unit_value = *extract_time_unit(unit)
      time - (unit_value * SECONDS_IN_UNIT[unit])
    end

    # @return [Array <Time>]
    def time_ago_range(upto, unit)
      unit, size = *extract_time_unit(unit)
      ago = time_ago(upto, unit => (size - 1))
      max, count, times = upto.to_i, ago.to_i, []
      begin
        times << Time.at(count)
      end while (count += SECONDS_IN_UNIT[unit]) <= max
      times
    end

    def uniquenesses_as_session_identifier(aspects)
      if (obj = aspects.flatten.reject { |u| blank?(u) }.first)
        object_as_session_identifier(obj)
      else
        NIL_SESSION_MEMBER
      end
    end

    def object_as_namespace(obj)
      case obj
      when String, Symbol
        obj.to_s
      else
        underscore(obj)
      end
    end

    def object_as_identifier(obj, opts = {})
      if obj.respond_to?(:as_member) || obj.respond_to?(:id)
        ''.tap do |s|
          s << "#{underscore(obj.class)}:" if opts[:namespace]
          s << (obj.respond_to?(:as_member) ? obj.as_member : obj.id).to_s
        end
      else
        opts[:encode] ? Base64.strict_encode64(obj.to_s) : obj.to_s
      end
    end

    def object_as_member(obj)
      object_as_identifier(obj)
    end

    def object_as_session_identifier(obj)
      object_as_identifier(obj, namespace: true)
    end

    def object_as_key(obj)
      object_as_identifier(obj, encode: true)
    end

  end
end
