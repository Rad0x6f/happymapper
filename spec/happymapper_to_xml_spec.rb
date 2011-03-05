require File.dirname(__FILE__) + '/spec_helper.rb'

module ToXML

  class Address
    include HappyMapper

    tag 'address'
    element :street, String
    element :postcode, String
    element :housenumber, String
    element :city, String
    element :country, String

    def initialize(parameters)
      parameters.each_pair do |property,value|
        send("#{property}=",value) if respond_to?("#{property}=")
      end
    end

  end

  describe "#to_xml" do

    context "Address" do
      
      before(:all) do
        address = Address.new('street' => 'Mockingbird Lane',
        'postcode' => '98103',
        'housenumber' => '1313',
        'city' => 'Seattle',
        'country' => 'USA' )
        @address_xml = Nokogiri::XML(address.to_xml).root
      end
      
      { 'street' => 'Mockingbird Lane',
        'postcode' => '98103',
        'housenumber' => '1313',
        'city' => 'Seattle',
        'country' => 'USA' }.each_pair do |property,value|
        
        it "should have the element '#{property}' with the value '#{value}'" do
          @address_xml.xpath("#{property}").text.should == value
        end
        
      end

    end


  end

end
