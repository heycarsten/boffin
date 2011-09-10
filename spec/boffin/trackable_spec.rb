require 'spec_helper'

describe Boffin::Trackable do
  before :all do
    SpecHelper.flush_keyspace!
    @mock = MockTrackableInjected.new(1)
    @mock.hit(:views, :unique => ['sess.1'])
    @mock.hit(:views, :unique => ['sess.1'])
  end

  it 'can be included' do
    MockTrackableIncluded.boffin.hit_types.should == [:views, :likes]
  end

  it 'can be injected' do
    MockTrackableInjected.boffin.hit_types.should == [:views, :likes]
  end

  it 'provides ::boffin as an accessor to the Tracker instance' do
    MockTrackableInjected.boffin.should be_a Boffin::Tracker
  end

  it 'delegates ::top_ids to the Tracker instance' do
    MockTrackableInjected.top_ids(:views, :days => 1).should == ['1']
  end

  it 'delegates #hit_count to the Tracker instance' do
    @mock.hit_count(:views).should == 2
  end

  it 'delegates #uhit_count to the Tracker instance' do
    @mock.uhit_count(:views).should == 1
  end

  it 'delegates #hit_count_for_session_id to the Tracker instance' do
    @mock.hit_count_for_session_id(:views, 'sess.1').should == 2
  end
end
