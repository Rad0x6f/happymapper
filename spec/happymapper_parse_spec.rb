require 'spec_helper'

describe HappyMapper do

  context ".parse" do

    context "on a single root node" do

      subject { described_class.parse fixture_file('address.xml') }

      it "should parse child elements" do
        subject.street.should == "Milchstrasse"
        subject.housenumber.should == "23"
        subject.postcode.should == "26131"
        subject.city.should == "Oldenburg"
      end

      it "should parse camelCased elements" do
        subject.mobile_phone.content.should == '89473928231'
      end

      it "should recognize several camelCased elements as has_many relationship" do
        subject.home_owner.size.should == 2
        subject.home_owner.first == 'Albert'
        subject.home_owner.last == 'Mayer'
      end

      it "should not create a content entry when the xml contents no text content" do
        subject.should_not respond_to :content
      end

      it "should combine attributes for multiple elements" do
        subject.home_owner.first.relation.should == 'none'
        subject.home_owner.last.relation.should == nil
        subject.home_owner.first.on_site.should == nil
        subject.home_owner.last.on_site.should == 'false'
      end

      context "child elements with attributes" do

        it "should parse the attributes" do
          subject.country.code.should == "de"
        end

        it "should parse camelCased attributes" do
          subject.mobile_phone.operator_name.should == "vodafone"
        end

        it "should parse the content" do
          subject.country.content.should == "Germany"
        end

      end

      end

    context "element names with special characters" do
      subject { described_class.parse fixture_file('ambigous_items.xml') }

      it "should create accessor methods with similar names" do
        subject.my_items.item.should be_kind_of Array
      end
    end

    context "element names with camelCased elements and Capital Letters" do

      subject { described_class.parse fixture_file('subclass_namespace.xml') }

      it "should parse the elements and values correctly" do
        subject.title.should == "article title"
        subject.photo.publish_options.author.should == "Stephanie"
        subject.gallery.photo.title.should == "photo title"
      end
    end

    context "several elements nested deep" do
      subject { described_class.parse fixture_file('ambigous_items.xml') }

      it "should parse the entire relationship" do
        subject.my_items.item.first.item.name.should == "My first internal item"
        subject.my_items.item.first.item.name.class.should_not == Array
        subject.others_items.item.last.name.class.should == Array
      end

      it "should combine multiple element children and properties" do
        subject.children.child.first.par1.should == "1"
        subject.children.child.first.par2.should == nil
        subject.children.child.first.name.first == "Michael"
        subject.children.child.first.name.last == nil
        subject.children.child.first.age == "14"
        subject.children.child.first.sibling.size == 0

        subject.children.child.last.par1.should == nil
        subject.children.child.last.par2.should == "2"
        subject.children.child.last.name.first == "Michelle"
        subject.children.child.last.name.last == "Michelle"
        subject.children.child.last.age == nil
        subject.children.child.last.sibling.size == 2
        subject.children.child.last.sibling.first == "Michael"
        subject.children.child.last.sibling.last == "Natasha"
      end

    end

    context "xml that contains multiple entries" do

      subject { described_class.parse fixture_file('multiple_primitives.xml') }

      it "should parse the elements as it would a 'has_many'" do

        subject.name.should == "value"
        subject.image.should == [ "image1", "image2" ]

      end

    end

    context "xml with multiple namespaces" do

      subject { described_class.parse fixture_file('subclass_namespace.xml') }

      it "should parse the elements an values correctly" do
        subject.title.should == "article title"
      end
    end

    context "after_parse callbacks" do
      module AfterParseSpec
        class Address
          include HappyMapper
          element :street, String
        end
      end

      after do
        AfterParseSpec::Address.after_parse_callbacks.clear
      end

      it "should callback with the newly created object" do
        from_cb = nil
        called = false
        cb1 = proc { |object| from_cb = object }
        cb2 = proc { called = true }
        AfterParseSpec::Address.after_parse(&cb1)
        AfterParseSpec::Address.after_parse(&cb2)

        object = AfterParseSpec::Address.parse fixture_file('address.xml')
        from_cb.should == object
        called.should == true
      end
    end

    context "can be nested in custom mapper" do
      class CustomAddress
        include HappyMapper
        tag 'address'
        has_one :street, String
        has_many :owners, HappyMapper, tag: 'homeOwner'
        has_one :old_address, HappyMapper, tag: 'oldAddress'
      end

      subject { CustomAddress.parse fixture_file('address.xml') }

      it "should have many anonymous owners" do
        subject.owners.size.should == 2
        subject.owners.first.relation.should == "none"
      end

      it "should have a single anonymous old address" do
        subject.street.should == "Milchstrasse"
        subject.old_address.street.should == "Front St"
      end

    end

  end  # context '.parse'

end