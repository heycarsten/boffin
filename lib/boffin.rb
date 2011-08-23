require 'base64'
require 'date'
require 'time'
require 'boffin/version'
require 'boffin/utils'
require 'boffin/config'
require 'boffin/keyspace'
require 'boffin/tracker'
require 'boffin/hit'
require 'boffin/trackable'

module Boffin
  WINDOW_UNIT_FORMATS = {
    hours:  '%F-%H',
    days:   '%F',
    months: '%Y-%m',
    years:  '%Y'
  }
  WINDOW_UNIT_TYPES = WINDOW_UNIT_FORMATS.keys

  class NoUniquenessError < StandardError; end

  def self.config(&block)
    @config ||= Config.new(&block)
  end
end
