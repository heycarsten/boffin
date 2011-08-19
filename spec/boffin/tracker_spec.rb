require 'spec_helper'

describe Boffin::Tracker do
  before :all do
    @tracker = Boffin::Tracker.new
  end

  describe '#uhit' do
    it 'throws an error if no unique objects are provided' do
      lambda {
        @tracker.uhit(:urls, '/test', :view, [nil, nil])
      }.should raise_error Boffin::NoUniquenessError
    end
  end

  describe '#hit' do
    after :all do
      BoffinSpecHelper.clear_redis_keyspace!
    end

    before :all do
      @tracker.hit(:urls, '/test',   :view)
      @tracker.hit(:urls, '/test',   :view, [nil])
      @tracker.hit(:urls, '/test/1', :view, [nil, 'sess.1'])
      @tracker.hit(:urls, '/test/1', :view, ['sess.1'])
    end

    it 'stores all hits without uniqueness' do
      @tracker.uhit_count(:urls, '/test', :view).should == 2
      @tracker.hit_count( :urls, '/test', :view).should == 2
    end

    it 'does not store hits with uniqueness more than once' do
      @tracker.uhit_count(:urls, '/test/1', :view).should == 1
      @tracker.hit_count( :urls, '/test/1', :view).should == 2
    end
  end

  describe '#hit_count' do
    before :all do
    end
  end

  describe '#uhit_count' do
    before :all do
    end
  end
end

describe Boffin::Tracker, '(unique tracking enabled)' do
  before :all do
    @tracker = Boffin::Tracker.new
    @tracker.config.disable_unique_tracking = true
  end

  after :all do
    BoffinSpecHelper.clear_redis_keyspace!
  end

  describe '#hit_count(ns, thing, type)'

  describe '#uhit_count(ns, thing, type)'

  describe '#top(ns, type, params = {})'

  describe '#utop(ns, type, params = {})'

  describe '#trending(ns, params = {})'

  describe '#utrending(ns, params = {})'
end
