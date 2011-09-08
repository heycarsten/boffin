require 'spec_helper'

class MockEmptyDitty < MockDitty; end

describe Boffin do
  describe '::track' do
    before do
      @tracker = Boffin.track(MockEmptyDitty, [:views, :tests])
    end

    it 'injects Trackable into a class' do
      MockEmptyDitty.include?(Boffin::Trackable).should be_true
    end

    it 'sets hit types' do
      MockEmptyDitty.boffin.hit_types.should == [:views, :tests]
    end

    it 'returns Trackable' do
      Boffin.track(:thing).should be_a Boffin::Tracker
    end
  end

  describe '::config' do
    before do
      @config = Boffin.config.dup
      Boffin.instance_variable_set(:@config, nil)
    end

    after do
      Boffin.instance_variable_set(:@config, @config)
    end

    it 'accepts a hash' do
      Boffin.config(:namespace => 'trendy')
      Boffin.config.namespace.should == 'trendy'
    end

    it 'accepts a block' do
      Boffin.config { |c| c.namespace = 'jazzy' }
      Boffin.config.namespace.should == 'jazzy'
    end
  end
end
