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

    context 'when Rails is present' do
      before { ::Rails = Struct.new(:env).new(env: 'development') }
      after  { Object.send(:remove_const, :Rails) } # :-(

      it 'includes the Rails.env environment into the namespace' do
        Boffin::Config.new.namespace == 'boffin:development'
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

  describe '#hour_window_secs' do
    specify { subject.hour_window_secs.should == 24 * 3600 } # 1 day
  end

  describe '#day_window_secs' do
    specify { subject.day_window_secs.should == 30 * 24 * 3600 } # 1 month
  end

  describe '#month_window_secs' do
    specify { subject.month_window_secs.should == 12 * 30 * 24 * 3600 } # 1 year
  end

  describe '#cache_expire_secs' do
    specify { subject.cache_expire_secs.should == 3600 } # 1 hour
  end

  describe '#object_id_proc' do
    it 'calls #to_s on the id of an object that responds to #id' do
      obj = MockClass.new
      subject.object_id_proc.(obj).should == '1'
    end

    it 'calls #to_s and base64 encodes the value of an object that does not respond to #id' do
      subject.object_id_proc.('hello-world').should == 'aGVsbG8td29ybGQ='
    end
  end

  describe '#object_as_unique_member_proc' do
    it 'calls #as_unique_member of an object that responds to it' do
      obj = Class.new { def as_unique_member; 'obj1'; end }.new
      subject.object_as_unique_member_proc.(obj).should == 'obj1'
    end

    it 'generates a member for objects that respond to #id' do
      obj = MockClass.new
      subject.object_as_unique_member_proc.(obj).should == 'mock_class:1'
    end
  end
end
