require File.dirname(__FILE__) + '/spec_helper.rb'
           

xml1 = %{
  <root>
    <description>some description</description>
    <blarg name='blargname1' href='http://blarg.com'/>
    <blarg name='blargname2' href='http://blarg.com'/>
    <jello name='jelloname' href='http://jello.com'/>
    <subelement>
      <jello name='subjelloname' href='http://ohnojello.com'/>
    </subelement>
  </root>      
}

module GenericBase
  class Base
    include HappyMapper
    tag '*'
    attribute :name, String
    attribute :href, String
  end
  class Root
    include HappyMapper     
    tag 'root'
    element :description, String
    has_many :blargs, Base, :tag => 'blarg'
    has_many :jellos, Base, :tag => 'jello'
  end
end


describe HappyMapper do

  it 'OMG HELLOP HELLO YEAHHHHHH' do
    root = GenericBase::Root.parse(xml1)    
    puts root.to_xml

  end
 

end
