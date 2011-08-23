require 'spec_helper'

class MockClass
  def id; 1; end
end

describe Boffin::Config do
  describe '#namespace' do
    specify { subject.namespace.should == 'boffin' }

    context 'when RAILS_ENV is present' do
      before { ENV['RAILS_ENV'] = 'production' }
      after  { ENV['RAILS_ENV'] = nil }

      it 'includes the Rails environment into the namespace' do
        Boffin::Config.new.namespace == 'boffin:production'
      end
    end

    context 'when RACK_ENV is present' do
      before { ENV['RACK_ENV'] = 'staging' }
      after  { ENV['RACK_ENV'] = nil }

      it 'includes the Rack environment into the namespace' do
        Boffin::Config.new.namespace == 'boffin:staging'
      end
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
    specify { subject.cache_expire_secs.should == 1800 } # 30 minute
  end

  describe '#object_as_member_proc' do
    it 'calls #as_member on the object if available' do
      obj = Class.new { def as_member; 'obj1'; end }.new
      subject.object_as_member_proc.(obj).should == 'obj1'
    end

    it 'calls #id.to_s on the object if available' do
      obj = Class.new { def id; 100; end }.new
      subject.object_as_member_proc.(obj).should == '100'
    end

    it 'calls #to_s on everything else' do
      subject.object_as_member_proc.(3.14).should == '3.14'
      subject.object_as_member_proc.(:symbol).should == 'symbol'
      subject.object_as_member_proc.('string').should == 'string'
    end
  end
end
