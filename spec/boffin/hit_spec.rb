require 'spec_helper'

describe Boffin::Hit, '::new' do
  context 'given session params' do
    before do
      SpecHelper.flush_keyspace!
      @tracker = Boffin::Tracker.new(MockDitty)
      @ditty   = MockDitty.new
      @user    = MockUser.new
      @hit     = Boffin::Hit.new(@tracker, :tests, @ditty, [nil, @user])
    end

  end

end
