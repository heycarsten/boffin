require 'spec_helper'

describe Boffin::Config do
  describe '#namespace' do
    specify { subject.namespace.should == 'boffin' }

    it 'includes the Rails environment when available' do
      ENV['RAILS_ENV'] = 'production'
      Boffin::Config.new.namespace.should == 'boffin:production'
      ENV['RAILS_ENV'] = nil
    end

    it 'includes the Rack environment when available' do
      ENV['RACK_ENV'] = 'staging'
      Boffin::Config.new.namespace.should == 'boffin:staging'
      ENV['RACK_ENV'] = nil
    end
  end

  describe '#new' do
    it 'returns a default config instance with no arguments' do
      Boffin::Config.new.should be_a Boffin::Config
    end

    it 'can be sent a block' do
      conf = Boffin::Config.new { |c| c.namespace = 'hihi' }
      conf.namespace.should == 'hihi'
    end
  end

  describe '#merge' do
    it 'copies the existing instance' do
      newconf = subject.merge(namespace: 'carsten')
      newconf.namespace.should == 'carsten'
      subject.namespace.should == 'boffin'
    end
  end

  describe '#redis' do
    it 'calls Redis.connect by default' do
      Boffin::Config.new.redis.should be_a Redis
    end
  end

  describe '#hours_window_secs' do
    specify { subject.hours_window_secs.should == 3 * 24 * 3600 } # 3 days
  end

  describe '#days_window_secs' do
    specify { subject.days_window_secs.should == 3 * 30 * 24 * 3600 } # 3 months
  end

  describe '#months_window_secs' do
    specify { subject.months_window_secs.should == 3 * 12 * 30 * 24 * 3600 } # 3 years
  end

  describe '#cache_expire_secs' do
    specify { subject.cache_expire_secs.should == 1800 } # 30 minutes
  end
end
