require File.dirname(__FILE__) + '/spec_helper.rb'

describe HappyMapper::Attribute do
  describe "initialization" do
    it 'should accept :default as an option' do
      attr = described_class.new(:foo, String, :default => 'foobar')
      attr.default.should == 'foobar'
    end
  end
end
