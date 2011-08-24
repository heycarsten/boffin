require 'spec_helper'

describe Boffin::Keyspace do
  before :all do
    @tracker  = Boffin::Tracker.new(MockDitty)
    @tracker.config.namespace = 'b'
    @ks  = @tracker.keyspace
    @uks = @tracker.keyspace(true)
  end

  describe '#root' do
    specify { @ks.root.should == 'b:mock_ditty' }
  end

  describe '#hits' do
    specify do
      @ks.hits([:views, :likes]).should == 'b:mock_ditty:views_likes:hits'
    end

    specify do
      @ks.hits(:views).should == 'b:mock_ditty:views:hits'
    end

    specify do
      @ks.hits(:views, MockDitty.new).should == 'b:mock_ditty.1:views:hits'
    end
  end

  describe '#hit_count' do
    specify do
      @ks.hit_count(:views, MockDitty.new).should == 'b:mock_ditty.1:views:hit_count'
    end
  end

  describe '#hits_union' do
    specify do
      @ks.hits_union(:views, :days, 5).
        should == 'b:mock_ditty:views:hits:current.days_5'
    end
  end

  describe '#hits_union_multi' do
    specify do
      @ks.hits_union_multi({ views: 1, likes: 3 }, :days, 5).
        should == 'b:mock_ditty:views_1_likes_3:hits:current.days_5'
    end
  end

  describe '#hits_window' do
    specify do
      @ks.hits_window(:views, '*').should == 'b:mock_ditty:views:hits.*'
    end
  end

  describe '#hits_time_window' do
    before do
      @time = Time.local(2011, 1, 1, 23)
    end

    Boffin::INTERVAL_TYPES.each do |format|
      describe "given #{format} based window" do
        specify do
          strf = Boffin::INTERVAL_FORMATS[format]
          @ks.hits_time_window(:views, format, @time).
            should == "b:mock_ditty:views:hits.#{@time.strftime(strf)}"
        end
      end
    end
  end

  describe '#hit_time_windows' do
    before do
      @time = Time.local(2011, 1, 1, 23)
    end

    it 'generates keys each interval in the range' do
      @ks.hit_time_windows(:views, :days, 3, @time).should == [
        'b:mock_ditty:views:hits.2010-12-30',
        'b:mock_ditty:views:hits.2010-12-31',
        'b:mock_ditty:views:hits.2011-01-01'
      ]
    end
  end
end
