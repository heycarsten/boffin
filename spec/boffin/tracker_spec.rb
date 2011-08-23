require 'spec_helper'

describe Boffin::Tracker do
  before :all do
    @tracker   = Boffin::Tracker.new(MockDitty, [:views, :likes, :shares])
    @instance1 = MockDitty.new(100)
    @instance2 = MockDitty.new(101)
    @instance3 = MockDitty.new(102)
    @user1     = MockUser.new(1)
    @user2     = MockUser.new(2)
    @time      = Time.local(2011, 1, 1)

    Timecop.freeze(@time) do
      @tracker.hit(:views, @instance1)
      @tracker.hit(:likes, @instance1, [@user1])
      @tracker.hit(:views, @instance1, [nil, 'sess.1'])
      @tracker.hit(:views, @instance1, [@user2])
      @tracker.hit(:views, @instance2, [nil, nil])
      @tracker.hit(:views, @instance3, [@user1])
      @tracker.hit(:views, @instance3, ['sess.1'])
      @tracker.hit(:views, @instance1, ['sess.2'])
      @tracker.hit(:views, @instance1, [@user1])
      @tracker.hit(:views, @instance3, [@user2])
    end
  end

  describe '#hit(hit_type, instance, uniquenesses = [])' do
    # Hit.new(self, hit_type, instance, uniquenesses)
  end

  describe '#hit_count(hit_type, instance)' do
    # redis.get(keyspace.hit_count(hit_type, instance))
  end

  describe '#uhit_count(hit_type, instance)' do
    # redis.zcard(keyspace.hits(hit_type, instance)).to_i
  end

  describe '#hit_count_for_session_id(hit_type, instance, sess_obj)' do
    # sessid = Utils.object_as_session_identifier(sess_obj)
    # redis.zscore(keyspace.hits(hit_type, instance), sessid).to_i
  end

  describe '#top' do
    it 'returns ids ordered by hit counts of weighted totals' do
      ids = @tracker.top({ views: 10, likes: 30 }, days: 3)
    end

    it 'returns ids ordered by total counts of a specific hit type' do
      ids = @tracker.top(:views, days: 3)
    end

    it 'returns ids in ascending order when passed order: "asc" as an option' do
      ids = @tracker.top(:views, days: 3, order: 'asc')
    end
  end

  describe '#utop' do
    it 'calculates results based on only unique hit data'
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