require 'spec_helper'

describe Boffin::Trackable, 'when mixed into a model' do
  before :all do
    Boffin.track(MockModel)
  end
end

describe Boffin::Trackable, 'when injected into a model' do
  before :all do
    
  end
end
