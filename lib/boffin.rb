require 'base64'
require 'boffin/version'
require 'boffin/utils'
require 'boffin/config'
require 'boffin/keyspace'
require 'boffin/tracker'
require 'boffin/reporter'

module Boffin
  class WithoutUniquenessError < StandardError; end

  def self.config(&block)
    @config ||= Config.new(&block)
  end

  def self.default_boffspace
    @default_boffspace ||= Boffspace.new(config)
  end
end
