module HappyMapper
  module AnonymousMapper
    
    #
    # Used internally when parsing to create a class that is capable of
    # parsing the content. The name of the class is of course not likely
    # going to match the content it will be able to parse so the tag
    # value is set to the one provided.
    #
    def create_happymapper_class_with_tag(tag_name)
      happymapper_class = Class.new
      happymapper_class.class_eval do
        include HappyMapper
        tag tag_name
      end
      happymapper_class
    end

    #
    # Used internally to create and define the necessary happymapper
    # elements.
    #
    def create_happymapper_class_with_element(element)
      happymapper_class = create_happymapper_class_with_tag(element.name)

      element.attributes.each do |name,attribute|
        define_attribute_on_class(happymapper_class,attribute)
      end

      element.children.each do |element|
        define_element_on_class(happymapper_class,element)
      end

      happymapper_class
    end


    #
    # Define a HappyMapper element on the provided class based on
    # the element provided.
    #
    def define_element_on_class(class_instance,element)

      # When a text element has been provided create the necessary
      # HappyMapper content attribute if the text happens to content
      # some content.

      if element.text? and element.content.strip != ""
        class_instance.content :content, String
      end

      # When the element has children elements, that are not text
      # elements, then we want to recursively define a new HappyMapper
      # class that will have elements and attributes.
      
      element_type = if !element.attributes.empty?
        create_happymapper_class_with_element(element)
      else
        String
      end

      class_instance.element element.name, element_type
    end

    #
    # Define a HappyMapper attribute on the provided class based on
    # the attribute provided.
    #
    def define_attribute_on_class(class_instance,attribute)
      class_instance.attribute attribute.name, String
    end

    def parse(xml_content)

      # TODO: this should be able to handle all the types of functionality that parse is able
      #   to handle which includes the text, xml document, node, fragment, etc.
      xml = Nokogiri::XML(xml_content)

      happymapper_class = create_happymapper_class_with_element(xml.root)

      # With all the elements and attributes defined on the class it is time
      # for the class to actually use the normal HappyMapper powers to parse
      # the content. At this point this code is utilizing all of the existing
      # code implemented for parsing.
      happymapper_class.parse(xml_content, :single => true)

    end

  end

end