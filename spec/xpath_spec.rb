require File.dirname(__FILE__) + '/spec_helper.rb'

test_xml = %{
  <rss>
    <item>
      <title>Test XML</title>
      <link href="link_to_resources" />
      <subitem>
        <detail>I want to parse this</detail>
        <more>more 1</more>
        <more>more 2</more>
      </subitem>
    </item>
  </rss>
  }

class Item
  include HappyMapper
  
  tag 'item'
  
  element :title, String
  attribute :link, String, :xpath => 'link/@href'
  element :detail, String, :xpath => 'subitem/detail'
  has_many :more_details, String, :xpath => 'subitem/more'
  
end


describe HappyMapper do
  
  it "should find the link href value" do
    @item.link.should == 'link_to_resources'
  end
  
  it "should find this subitem based on the xpath" do
    @item.detail.should == 'I want to parse this'
  end
  
  it "should find the subitems based on the xpath" do
    @item.more_details.length.should == 2
  end
  
  before(:all) do
    @item = Item.parse(test_xml,:single => true)
  end
  
end