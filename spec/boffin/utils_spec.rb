require 'spec_helper'

describe Boffin::Utils do
  describe '::underscore' do
    it 'works with namespaces' do
      subject.underscore('MyMod::MyClass').should == 'my_mod_my_class'
    end

    it 'works without namespaces' do
      subject.underscore('MyMod').should == 'my_mod'
      subject.underscore('Mod').should == 'mod'
    end

    it 'works with blank strings' do
      subject.underscore('').should == ''
      subject.underscore(' ').should == ' '
    end
  end

  describe '::quick_token' do
    it 'generates tokens' do
      subject.quick_token.should be_a String
      subject.quick_token.length.should > 6
    end
  end

  describe '::blank?' do
    it 'returns true for []' do
      subject.blank?([]).should be_true
    end

    it 'returns true for {}' do
      subject.blank?({}).should be_true
    end

    it 'returns true for nil' do
      subject.blank?(nil).should be_true
    end

    it 'returns true for ""' do
      subject.blank?('').should be_true
    end

    it 'returns true for false' do
      subject.blank?(false).should be_true
    end

    it 'returns false for non-blank things' do
      subject.blank?(0).should be_false
    end
  end
end
