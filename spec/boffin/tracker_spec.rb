require 'spec_helper'

describe Boffin::Tracker do
  before :all do
    @tracker = Boffin::Tracker.new
    @time    = Time.local(2011, 1, 1)

    Timecop.freeze(@time) do
      @tracker.hit(:urls, '/test',   :view)
      @tracker.hit(:urls, '/test',   :view, [nil])
      @tracker.hit(:urls, '/test',   :view, ['sess.2'])
      @tracker.hit(:urls, '/test',   :view, ['sess.2'])
      @tracker.hit(:urls, '/test/1', :view, [nil, 'sess.1'])
      @tracker.hit(:urls, '/test/1', :view, ['sess.1'])
    end
  end

  after :all do
    BoffinSpecHelper.clear_redis_keyspace!
  end

  describe '#uhit' do
    it 'refuses to store hits without any uniqueness' do
      lambda {
        @tracker.uhit(:urls, '/test', :view, [nil, nil])
      }.should raise_error Boffin::NoUniquenessError
    end
  end

  describe '#hit' do
    it 'stores hits without any uniqueness as unique' do
      @tracker.uhit_count(:urls, '/test', :view).should == 3
      @tracker.hit_count(:urls, '/test', :view).should == 4
    end

    it 'does not store hits with the same uniqueness more than once' do
      @tracker.uhit_count(:urls, '/test/1', :view).should == 1
      @tracker.hit_count(:urls, '/test/1', :view).should == 2
    end

    it 'increments members in each time-windowed zset' do
    end

    it 'increments associated member in time-windowed zset' do
      $redis.@tracker.ks.hits_time_window_key(:urls, :view, :hours, @time)
    end

    it 'increments associated member in unique time-windowed zsets if unique' do
      
    end
  end

  describe '#hit_count' do
    it 'returns a count of all hits ever made' do
      @tracker.hit_count(:urls, '/test', :view).should == 4
    end
  end

  describe '#uhit_count' do
    it 'returns a count of all unique hits ever made' do
      @tracker.uhit_count(:urls, '/test', :view).should == 3
    end
  end

  describe '#top' do
    before do
    end
  end
end

describe Boffin::Tracker, '(unique tracking disabled)' do
  before :all do
    @tracker = Boffin::Tracker.new
    @tracker.config.disable_unique_tracking = true
  end

  after do
    BoffinSpecHelper.clear_redis_keyspace!
  end

  describe '#top(ns, type, params = {})'

  describe '#utop(ns, type, params = {})'

  describe '#trending(ns, params = {})'

  describe '#utrending(ns, params = {})'
end
