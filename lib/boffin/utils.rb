module Boffin
  # A collection of utility methods that are used throughout the library
  module Utils

    # The number of seconds in an hour
    SECONDS_IN_HOUR  = 3600

    # Number of seconds in a day
    SECONDS_IN_DAY   = 24 * SECONDS_IN_HOUR

    # Number of seconds in a month
    SECONDS_IN_MONTH = 30 * SECONDS_IN_DAY

    # Number of seconds for a single value of each unit
    SECONDS_IN_UNIT  = {
      :hours  => SECONDS_IN_HOUR,
      :days   => SECONDS_IN_DAY,
      :months => SECONDS_IN_MONTH
    }

    module_function

    # @param [#to_s] thing
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

    # @param [Object] obj any Ruby object
    # @return [true, false]
    #   `true` if the provided object responds to :id, other than it's
    #   internal object identifier
    #   `false` if the object does not respond to :id
    def respond_to_id?(obj)
      # NOTE: this feels like a hack. I'm sure there is a more elegant way
      # to determine whether the :id method is the built in Object#id but
      # I can't think of it
      if RUBY_VERSION < "1.9"
        obj.respond_to?(:id) and obj.id != obj.object_id
      else
        obj.respond_to?(:id)
      end
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

    # @example
    #   time_ago(Time.local(2011, 1, 3), days: 2)
    #   # => 2011-01-01 00:00:00
    # @param [Time] time
    #   The initial time that the offset will be calculated from
    # @param [Hash] unit
    #   (see {#extract_time_unit})
    # @return [Time]
    #   The time in the past offset by the specified amount
    def time_ago(time, unit)
      unit, unit_value = *extract_time_unit(unit)
      time - (unit_value * SECONDS_IN_UNIT[unit])
    end

    # @param [Time] upto
    #   The base time of which to calculate the range from
    # @param [Hash] unit
    #   (see {#extract_time_unit})
    # @return [Array<Time>]
    #   An array of times in the calculated range
    # @example
    #   time_ago_range(Time.local(2011, 1, 5), days: 3)
    #   # => [2011-01-03 00:00:00, 2011-01-04 00:00:00, 2011-01-05 00:00:00]
    def time_ago_range(upto, unit)
      unit, size = *extract_time_unit(unit)
      ago = time_ago(upto, unit => (size - 1))
      max, count, times = upto.to_i, ago.to_i, []
      begin
        times << Time.at(count)
      end while (count += SECONDS_IN_UNIT[unit]) <= max
      times
    end

    # Generates a set member based off the first object in the provided array
    # that is not `nil`. If the array is empty or only contains `nil` elements
    # then {Boffin::NIL_SESSION_MEMBER} is returned.
    # @param [Array] aspects
    #   An array of which the first non-nil element is passed to
    #   {#object_as_session_identifier}
    # @return [String]
    def uniquenesses_as_session_identifier(aspects)
      if (obj = aspects.flatten.reject { |u| blank?(u) }.first)
        object_as_session_identifier(obj)
      else
        NIL_SESSION_MEMBER
      end
    end

    # @param [String, Symbol, Object] obj
    # @return [String]
    #   Returns a string that can be used as a namespace in Redis keys
    def object_as_namespace(obj)
      case obj
      when String, Symbol
        obj.to_s
      else
        underscore(obj)
      end
    end

    # @param [#as_member, #id, #to_s] obj
    # @param [Hash] opts
    # @option opts [true, false] :namespace
    #   If `true` the generated value will be prefixed with a namespace
    # @option opts [true, false] :encode
    #   If `true` and object fails to respond to `#as_member` or `#id`, the
    #   generated value will be Base64 encoded.
    # @return [String]
    def object_as_identifier(obj, opts = {})
      if obj.respond_to?(:as_member) || respond_to_id?(obj)
        ''.tap do |s|
          s << "#{underscore(obj.class)}:" if opts[:namespace]
          s << (obj.respond_to?(:as_member) ? obj.as_member : obj.id).to_s
        end
      else
        opts[:encode] ? [obj.to_s].pack("m0").chomp : obj.to_s
      end
    end

    # @return [String]
    # @param [#as_member, #id, #to_s] obj
    # @return [String] A string that can be used as a member in
    #   {Keyspace#hits_time_window}.
    # @see #object_as_identifier
    def object_as_member(obj)
      object_as_identifier(obj)
    end

    # @param [#as_member, #id, #to_s] obj
    # @return [String] A string that can be used as a member in {Keyspace#hits}.
    # @see #object_as_identifier
    def object_as_session_identifier(obj)
      object_as_identifier(obj, :namespace => true)
    end

    # @param [#as_member, #id, #to_s] obj
    # @return [String] A string that can be used as part of a Redis key
    # @see #object_as_identifier
    def object_as_key(obj)
      object_as_identifier(obj, :encode => true)
    end

  end
end
