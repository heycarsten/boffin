require 'spec_helper'

describe Boffin::Tracker do
  before :all do
    SpecHelper.flush_keyspace!
    @tracker   = Boffin::Tracker.new(MockDitty, [:views, :likes, :shares])
    @instance1 = MockDitty.new(100)
    @instance2 = MockDitty.new(200)
    @instance3 = MockDitty.new(300)
    @instance4 = MockDitty.new(400)
    @user1     = MockUser.new(1)
    @user2     = MockUser.new(2)
    @date      = Date.today

    Timecop.freeze(@date - 2) do
      @tracker.hit(:views, @instance3)
      @tracker.hit(:likes, @instance3, :unique => [@user1])
      @tracker.hit(:views, @instance3, :unique => ['sess.1'])
      @tracker.hit(:views, @instance3, :unique => ['sess.2'])
      @tracker.hit(:views, @instance3, :unique => [@user2])
      @tracker.hit(:likes, @instance1, :unique => [nil, nil])
      @tracker.hit(:views, @instance3, :unique => ['sess.4'])
      @tracker.hit(:views, @instance3, :unique => [@user1])
      @tracker.hit(:views, @instance2, :unique => [@user2])
      @tracker.hit(:views, @instance3, :unique => [@user2])
      @tracker.hit(:likes, @instance3)
      @tracker.hit(:views, @instance3, :unique => ['sess.1'])
      @tracker.hit(:views, @instance3)
      @tracker.hit(:likes, @instance3, :unique => [@user1])
      @tracker.hit(:views, @instance3, :unique => ['sess.1'], :increment => 2)
    end

    Timecop.freeze(@date - 1) do
      @tracker.hit(:views, @instance1)
      @tracker.hit(:likes, @instance2, :unique => [@user1])
      @tracker.hit(:views, @instance2, :unique => ['sess.4'])
      @tracker.hit(:views, @instance2, :unique => [nil, @user1])
      @tracker.hit(:views, @instance2, :unique => ['sess.3'])
      @tracker.hit(:views, @instance1, :unique => ['sess.3'])
      @tracker.hit(:views, @instance1, :unique => [@user1])
      @tracker.hit(:views, @instance2, :unique => ['sess.2'])
      @tracker.hit(:views, @instance1, :unique => [@user1])
      @tracker.hit(:views, @instance1, :unique => [@user2])
    end

    @tracker.hit(:views, @instance3, :unique => ['sess.2'])
    @tracker.hit(:views, @instance2, :unique => [@user2])
    @tracker.hit(:likes, @instance2)
    @tracker.hit(:views, @instance2, :unique => [@user1])
    @tracker.hit(:views, @instance1, :unique => ['sess.4'])
    @tracker.hit(:views, @instance3, :unique => ['sess.3'])
    @tracker.hit(:views, @instance1, :unique => [@user1])
    @tracker.hit(:views, @instance1, :unique => [@user2])
  end

  describe '#hit' do
    it 'throws an error if the hit type is not in the list' do
      lambda  { @tracker.hit(:view, @instance1) }.
        should raise_error Boffin::UndefinedHitTypeError
    end
  end

  describe '#hit_count' do
    it 'throws an error if the hit type is not in the list' do
      lambda  { @tracker.hit_count(:view, @instance1) }.
        should raise_error Boffin::UndefinedHitTypeError
    end

    it 'returns the raw hit count for the instance' do
      @tracker.hit_count(:views, @instance1).should == 8
    end

    it 'returns 0 for an instance that was never hit' do
      @tracker.hit_count(:views, 'neverhit').should == 0
    end

    it 'returns the unique hit count for the instance' do
      @tracker.hit_count(:views, @instance1, :unique => true).should == 5
    end

    it 'returns 0 for an instance that was never hit' do
      @tracker.hit_count(:likes, @instance4, :unique => true).should == 0
    end
  end

  describe '#hit_count_for_session_id' do
    it 'throws an error if the hit type is not in the list' do
      lambda  { @tracker.hit_count_for_session_id(:view, @instance1, 'sess.1') }.
        should raise_error Boffin::UndefinedHitTypeError
    end

    it 'returns the number of times the instance was hit by the session id' do
      @tracker.hit_count_for_session_id(:views, @instance3, 'sess.1').should == 3
    end

    it 'returns a count of 0 if the session id never hit the instance' do
      @tracker.hit_count_for_session_id(:views, @instance1, 'nohit').should == 0
    end
  end

  describe '#top' do
    it 'throws an error if passed hit type is invalid' do
      lambda  { @tracker.top(:view, :days => 3) }.
        should raise_error Boffin::UndefinedHitTypeError
    end

    it 'throws an error if passed weights with hit type that is invalid' do
      lambda  { @tracker.top({ :view => 1 }, :days => 3) }.
        should raise_error Boffin::UndefinedHitTypeError
    end

    it 'returns ids ordered by hit counts of weighted totals' do
      ids = @tracker.top({ :views => 1, :likes => 2 }, :days => 3)
      ids.should == ['300', '200', '100']
    end

    it 'returns ids ordered by total counts of a specific hit type' do
      ids = @tracker.top(:views, :days => 3)
      ids.should == ['300', '100', '200']
    end

    it 'returns ids in ascending order when passed { order: "asc" } as an option' do
      ids = @tracker.top(:views, :days => 3, :order => 'asc')
      ids.should == ['200', '100', '300']
    end

    it 'returns ids and counts when passed { counts: true } as an option' do
      ids = @tracker.top(:views, :days => 3, :counts => true)
      ids.should == [
        ['300', 13],
        ['100', 8],
        ['200', 7]
      ]
    end

    it 'returns ids based on unique hit data when passed { unique: true } as an option' do
      ids = @tracker.top(:views, :days => 3, :counts => true, :unique => true)
      ids.should == [
        ['300', 7],
        ['200', 5],
        ['100', 5]
      ]
    end
  end

  describe '#keyspace' do
    it 'returns a keyspace' do
      @tracker.keyspace.unique_namespace?.should be_false
    end

    it 'returns a unique keyspace when passed true' do
      @tracker.keyspace(true).unique_namespace?.should be_true
    end
  end
end
