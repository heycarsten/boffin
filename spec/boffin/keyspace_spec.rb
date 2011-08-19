require 'spec_helper'

describe Boffin::Keyspace do
  before :all do
    @ks = Boffin::Keyspace.new
    @ks.config.namespace = 'b'
  end

  describe '#root' do
    specify { @ks.root(:profile).should == 'b:profile' }
  end

  describe '#hits_key' do
    specify do
      @ks.hits_key(:profile, :views, :likes).
        should == 'b:profile:views_likes:hits'
    end

    specify do
      @ks.hits_key(:profile, :views).should == 'b:profile:views:hits'
    end
  end

  describe '#hits_union_key' do
    specify do
      @ks.hits_union_key(:profile, :views, :days, 5).
        should == 'b:profile:views:hits:current.days_5'
    end
  end

  describe '#combi_hits_union_key' do
    specify do
      @ks.combi_hits_union_key(:profile, { views: 1, likes: 3 }, :days, 5).
        should == 'b:profile:views_1_likes_3:hits:current.days_5'
    end
  end

  describe '#hits_window_key' do
    specify do
      @ks.hits_window_key(:profile, :views, '*').
        should == 'b:profile:views:hits.*'
    end
  end

  describe '#hits_time_window_key' do
    before do
      @time = Time.local(2011, 1, 1, 23)
    end

    Boffin::WINDOW_UNIT_TYPES.each do |format|
      describe "given #{format} based window" do
        specify do
          strf = Boffin::WINDOW_UNIT_FORMATS[format]
          @ks.hits_time_window_key(:profile, :views, format, @time).
            should == "b:profile:views:hits.#{@time.strftime(strf)}"
        end
      end
    end
  end

  describe '#object_root' do
    specify do
      @ks.object_root(:profile, 6, :views).
        should == 'b:profile.6:views'
    end
  end

  describe '#object_hits_key' do
    specify do
      @ks.object_hits_key(:profile, 6, :views).
        should == 'b:profile.6:views.hits'
    end
  end

  describe '#object_hit_count_key' do
    specify do
      @ks.object_hit_count_key(:profile, 6, :views).
        should == 'b:profile.6:views.hit_count'
    end
  end
end
