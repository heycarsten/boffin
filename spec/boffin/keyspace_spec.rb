require 'spec_helper'

describe Boffin::Keyspace do
  describe '#root' do
    specify { subject.root(:profile).should == 'boffin:profile' }
  end

  describe '#hits_key' do
    specify do
      subject.hits_key(:profile, :views, :likes).
        should == 'boffin:profile:views_likes:hits'
    end

    specify do
      subject.hits_key(:profile, :views).should == 'boffin:profile:views:hits'
    end
  end

  describe '#hits_union_key' do
    specify do
      subject.hits_union_key(:profile, :views, 5).
        should == 'boffin:profile:views:hits:current.5'
    end
  end

  describe '#combi_hits_union_key' do
    specify do
      subject.combi_hits_union_key(:profile, { views: 1, likes: 3 }, 5).
        should == 'boffin:profile:views_1_likes_3:hits:current.5'
    end
  end

  describe '#hits_window_key' do
    specify do
      subject.hits_window_key(:profile, :views, '*').
        should == 'boffin:profile:views:hits.*'
    end
  end

  describe '#hits_time_window_key' do
    before do
      @time = Time.local(2011, 1, 1, 23)
    end

    [:hour, :day, :month].each do |format|
      describe "given #{format} based window" do
        specify do
          strf = Boffin::Keyspace::WINDOW_FORMATS[format]
          subject.hits_time_window_key(:profile, :views, format, @time).
            should == "boffin:profile:views:hits.#{@time.strftime(strf)}"
        end
      end
    end
  end

  describe '#object_root' do
    specify do
      subject.object_root(:profile, 6, :views).
        should == 'boffin:profile.6:views'
    end
  end

  describe '#object_hits_key' do
    specify do
      subject.object_hits_key(:profile, 6, :views).
        should == 'boffin:profile.6:views.hits'
    end
  end

  describe '#object_hit_count_key' do
    specify do
      subject.object_hit_count_key(:profile, 6, :views).
        should == 'boffin:profile.6:views.hit_count'
    end
  end
end
