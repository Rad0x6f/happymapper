module HappyMapper
  module AnonymousMapper

    def parse(node_or_xml, options = {:single => true})
      if node_or_xml.is_a?(Nokogiri::XML::Document)
        node = node_or_xml.root
      elsif node_or_xml.is_a?(Nokogiri::XML::Node)
        node = node_or_xml
      else
        node = Nokogiri::XML(node_or_xml).root
      end

      raise ArgumentError, 'Parse argument is not valid xml' if node.nil?

      # If options were passed and they contain a :tag or a :name, then a HappyMapper element was defined within a 
      # custom mapper class. In that case, we search for the element(s) within the node

      tag_name = options[:tag] || options[:name]
      if not tag_name.nil?
        if not options[:xpath].nil?
          xpath = options[:xpath].to_s.sub(/([^\/])$/, '\1/')
        else
          xpath = (tag_name == node.name ? '/' : './')
        end
        nodes = node.xpath( namespacify(xpath + tag_name, options[:namespace] || options[:tag_namespace]), options[:namespaces] )
      else
        nodes = [node]
      end

      # iterate all nodes, incrementally building a happymapper class in the process
      happymapper_class = nil
      nodes.each{|n| happymapper_class = create_happymapper_class_with_element(n, happymapper_class) }


      # With all the elements and attributes defined on the class it is time
      # for the class to actually use the normal HappyMapper powers to parse
      # the content. At this point this code is utilizing all of the existing
      # code implemented for parsing.
      happymapper_class && happymapper_class.parse(node_or_xml, options)

    end

    #
    # Returns the xpath with all elements within the xpath expanded with the provided namespace
    # (unless the element is already prefixed with a namespace)
    #
    def namespacify(xpath, namespace)
      namespace = namespace.to_s if namespace.is_a? Symbol
      if(namespace.is_a?(String) && namespace.size > 0 && xpath.is_a?(String))
        parts = xpath.split '/', -1
        xpath = nil
        parts.each{|part|
          if xpath.nil?
            # This is only true in the first iteration. No need for the path delimiter
            xpath = ''
          else
            # make sure to add the path delimiter that we split apart earlier
            xpath += '/' 
          end
          # check if it's a valid element name
          if part =~ /^[a-zA-Z_][a-zA-Z_0-9\-\.]*$/
            xpath += "#{namespace}:#{part}"
          else
            xpath += part
          end
        } 
      end
      xpath 
    end

    private

    #
    # Borrowed from Active Support to convert unruly element names into a format
    # known and loved by Rubyists.
    #
    def underscore(camel_cased_word)
      word = camel_cased_word.to_s.dup
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end

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
    # Used internally to create a class and define the necessary happymapper elements.
    # @param [Nokogiri::XML::Node] element the node for which to declare and define a class
    # @param [Class] happymapper_class use this class instead of creating one
    #
    def create_happymapper_class_with_element(element, happymapper_class=nil)
      happymapper_class ||= create_happymapper_class_with_tag(element.name)

      happymapper_class.namespace element.namespace.prefix if element.namespace

      element.namespaces.each do |prefix,namespace|
        happymapper_class.register_namespace prefix, namespace
      end

      element.attributes.each do |name,attribute|
        define_attribute_on_class(happymapper_class,attribute)
      end

      seen = {}
      element.children.each do |element|
        define_element_on_class( happymapper_class,element, seen.key?(element.name) )
        seen[element.name] = true
      end

      happymapper_class
    end


    #
    # Define a HappyMapper element on the provided class based on
    # the element provided.
    #
    def define_element_on_class(class_instance, element, was_seen)

      # When a text element has been provided create the necessary
      # HappyMapper content attribute if the text happens to content
      # some content.

      if element.text? and element.content.strip != ""
        class_instance.content :content, String
      end

      # If there is already an element defined for this class, then make sure to use that element's type
      # instead of creating another one. This ensures that the attributes and elements of the type are merged

      underscore_element_name = underscore(element.name)
      happymapper_element = class_instance.elements.find {|e| e.name == underscore_element_name }
      element_type = happymapper_element && happymapper_element.type

      # When the element has children elements, that are not text
      # elements, then we want to recursively define a new HappyMapper
      # class that will have elements and attributes.

      element_type = if !element.elements.reject {|e| e.text? }.empty? or !element.attributes.empty?
        create_happymapper_class_with_element(element, element_type)
      else
        String
      end

      if happymapper_element.nil?
        method = :has_one
      elsif happymapper_element.options[:single] == false
        method = :has_many
      else
        method = was_seen ? :has_many : :has_one
      end

      class_instance.send(method, underscore_element_name, element_type, tag: element.name)
    end

    #
    # Define a HappyMapper attribute on the provided class based on
    # the attribute provided.
    #
    def define_attribute_on_class(class_instance,attribute)
      class_instance.attribute underscore(attribute.name), String, tag: attribute.name
    end

  end # module AnonymousMapper

end