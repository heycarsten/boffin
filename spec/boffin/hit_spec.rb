require 'spec_helper'

describe Boffin::Hit, '::new' do
  before do
    SpecHelper.flush_keyspace!
    @tracker = Boffin::Tracker.new(MockDitty)
    @ditty   = MockDitty.new
    @user    = MockUser.new
    Timecop.travel(Time.local(2011, 1, 1))
  end

  after do
    Timecop.return
  end

  it 'stores hit data under the appropriate keys' do
    Boffin::Hit.new(@tracker, :tests, @ditty, :unique => [nil, @user])
    [:hours, :days, :months].each do |interval|
      @tracker.top(:tests, interval => 1, :counts => true).
        should == [['1', 1]]
      @tracker.top(:tests, interval => 1, :counts => true, :unique => true).
        should == [['1', 1]]
    end
    @tracker.count(:tests, @ditty).should == 1
    @tracker.count(:tests, @ditty, :unique => true).should == 1
  end

  it 'does not store data under unique keys if the hit is not unique' do
    Boffin::Hit.new(@tracker, :tests, @ditty, :unique => [nil, @user])
    Boffin::Hit.new(@tracker, :tests, @ditty, :unique => [nil, @user])
    [:hours, :days, :months].each do |interval|
      @tracker.top(:tests, interval => 1, :counts => true).
        should == [['1', 2]]
      @tracker.top(:tests, interval => 1, :counts => true, :unique => true).
        should == [['1', 1]]
    end
    @tracker.count(:tests, @ditty, :unique => @user).should == 2
    @tracker.count(:tests, @ditty).should == 2
    @tracker.count(:tests, @ditty, :unique => true).should == 1
  end

  it 'allows arbitrary hit increments' do
    Boffin::Hit.new(@tracker, :tests, @ditty, :unique => [nil, @user], :increment => 5)
    Boffin::Hit.new(@tracker, :tests, @ditty, :unique => [nil, @user], :increment => 5)
    [:hours, :days, :months].each do |interval|
      @tracker.top(:tests, interval => 1, :counts => true).
        should == [['1', 10]]
      @tracker.top(:tests, interval => 1, :counts => true, :unique => true).
        should == [['1', 5]]
    end
  end
end
