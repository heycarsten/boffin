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
    Boffin::Hit.new(@tracker, :tests, @ditty, [nil, @user])
    [:hours, :days, :months].each do |interval|
      @tracker.top(:tests, interval => 1, counts: true).
        should == [['1', 1]]
      @tracker.top(:tests, interval => 1, counts: true, unique: true).
        should == [['1', 1]]
    end
    @tracker.hit_count(:tests, @ditty).should == 1
    @tracker.uhit_count(:tests, @ditty).should == 1
  end

  it 'does not store data under unique keys if the hit is not unique' do
    Boffin::Hit.new(@tracker, :tests, @ditty, [nil, @user])
    Boffin::Hit.new(@tracker, :tests, @ditty, [nil, @user])
    [:hours, :days, :months].each do |interval|
      @tracker.top(:tests, interval => 1, counts: true).
        should == [['1', 2]]
      @tracker.top(:tests, interval => 1, counts: true, unique: true).
        should == [['1', 1]]
    end
    @tracker.hit_count_for_session_id(:tests, @ditty, @user).should == 2
    @tracker.hit_count(:tests, @ditty).should == 2
    @tracker.uhit_count(:tests, @ditty).should == 1
  end

end
