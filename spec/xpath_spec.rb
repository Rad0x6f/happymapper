require File.dirname(__FILE__) + '/spec_helper.rb'

test_xml = %{
  <rss>
    <item>
      <title>Test XML</title>
      <link href="link_to_resources" />
    </item>
  </rss>
  }

class Item
  include HappyMapper
  
  tag 'item'
  
  attribute :link, String, :xpath => 'link/@href'
  
end


describe HappyMapper do
  
  it "should find the link href value" do
    @item.link.should == 'link_to_resources'
  end
  
  
  
  before(:all) do
    @item = Item.parse(test_xml,:single => true)
  end
  
end