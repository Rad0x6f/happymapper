require 'nokogiri'
require 'date'
require 'time'

class Boolean; end
class XmlContent; end

module HappyMapper

  DEFAULT_NS = "happymapper"

  def self.included(base)
    base.instance_variable_set("@attributes", {})
    base.instance_variable_set("@elements", {})
    base.instance_variable_set("@registered_namespaces", {})

    base.extend ClassMethods
  end

  module ClassMethods
    def attribute(name, type, options={})
      attribute = Attribute.new(name, type, options)
      @attributes[to_s] ||= []
      @attributes[to_s] << attribute
      attr_accessor attribute.method_name.intern
    end

    def attributes
      @attributes[to_s] || []
    end

    def register_namespace(namespace, ns)
      @registered_namespaces.merge!({namespace => ns})
    end

    def element(name, type, options={})
      element = Element.new(name, type, options)
      @elements[to_s] ||= []
      @elements[to_s] << element
      attr_accessor element.method_name.intern
    end

    def elements
      @elements[to_s] || []
    end

    def text_node(name, type, options={})
      @text_node = TextNode.new(name, type, options)
      attr_accessor @text_node.method_name.intern
    end

    def has_xml_content
      attr_accessor :xml_content
    end

    def has_one(name, type, options={})
      element name, type, {:single => true}.merge(options)
    end

    def has_many(name, type, options={})
      element name, type, {:single => false}.merge(options)
    end

    # Specify a namespace if a node and all its children are all namespaced
    # elements. This is simpler than passing the :namespace option to each
    # defined element.
    def namespace(namespace = nil)
      @namespace = namespace if namespace
      @namespace
    end

    def tag(new_tag_name)
      @tag_name = new_tag_name.to_s unless new_tag_name.nil? || new_tag_name.to_s.empty?
    end

    def tag_name
      @tag_name ||= to_s.split('::')[-1].downcase
    end

    def parse(xml, options = {})
      # locally scoped copy of namespace for this parse run
      namespace = @namespace

      if xml.is_a?(Nokogiri::XML::Node)
        node = xml
      else
        if xml.is_a?(Nokogiri::XML::Document)
          node = xml.root
        else
          xml = Nokogiri::XML(xml)
          node = xml.root
        end

        root = node.name == tag_name
      end

      # This is the entry point into the parsing pipeline, so the default
      # namespace prefix registered here will propagate down
      namespaces   = options[:namespaces]
      namespaces ||= {}
      namespaces   = namespaces.merge(xml.collect_namespaces) if xml.respond_to?(:collect_namespaces)
      namespaces   = namespaces.merge(@registered_namespaces)

      if options[:namespace]
        namespace = options[:namespace]
      elsif namespaces.has_key?("xmlns")
        namespace ||= DEFAULT_NS
        namespaces[namespace] = namespaces.delete("xmlns")
      elsif namespaces.has_key?(DEFAULT_NS)
        namespace ||= DEFAULT_NS
      end

      nodes = options.fetch(:nodes) do
        xpath  = (root ? '/' : './/')
        xpath  = options[:xpath].to_s.sub(/([^\/])$/, '\1/') if options[:xpath]
        xpath += "#{namespace}:" if namespace
        #puts "parse: #{xpath}"

        nodes = []

        # when finding nodes, do it in this order:
        # 1. specified tag
        # 2. name of element
        # 3. tag_name (derived from class name by default)
        
        
        [options[:tag], options[:name], tag_name].compact.each do |xpath_ext|
          begin
          nodes = node.xpath(xpath + xpath_ext.to_s, namespaces)
          rescue
            break
          end
          break if nodes && !nodes.empty?
        end

        nodes
      end

      
      collection = nodes.collect do |n|
        obj = new

        attributes.each do |attr|
          obj.send("#{attr.method_name}=",
                    attr.from_xml_node(n, namespace, namespaces))
        end

        elements.each do |elem|
          obj.send("#{elem.method_name}=",
                    elem.from_xml_node(n, namespace, namespaces))
        end

        obj.send("#{@text_node.method_name}=",
                  @text_node.from_xml_node(n, namespace, namespaces)) if @text_node

        if obj.respond_to?('xml_content=')
          n = n.children if n.respond_to?(:children)
          obj.xml_content = n.to_xml
        end

        obj
      end

      # per http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Document.html#M000354
      nodes = nil

      if options[:single] || root
        collection.first
      else
        collection
      end
    end
  
  end
  
  #
  # Create an xml representation of the specified class based on defined
  # HappyMapper elements and attributes. The method is defined in a way
  # that it can be called recursively by classes that are also HappyMapper
  # classes, allowg for the composition of classes.
  #
  def to_xml(builder = nil,default_namespace = nil)
    
    #
    # If to_xml has been called without a passed in builder instance that
    # means we are going to return xml output. When it has been called with
    # a builder instance that means we most likely being called recursively
    # and will return the end product as a builder instance. 
    #
    unless builder
      write_out_to_xml = true
      builder = Nokogiri::XML::Builder.new
    end
    
    #
    # Find the attributes for the class and collect them into an array
    # that will be placed into a Hash structure
    #
    attributes = self.class.attributes.collect do |attribute|
      
      value = send(attribute.method_name)
      
      #
      # If the attribute defines an on_save lambda/proc or value that maps to 
      # a method that the class has defined, then call it with the value as a
      # parameter.
      #
      if on_save_action = attribute.options[:on_save]
        if on_save_action.is_a?(Proc)
          value = on_save_action.call(value)
        elsif respond_to?(on_save_action)
          value = send(on_save_action,value)
        end
      end
      
      #
      # Attributes that have a nil value should be ignored unless they explicitly
      # state that they should be expressed in the output.
      #
      if value || attribute.options[:state_when_nil]
        attribute_namespace = attribute.options[:namespace] || default_namespace
        [ "#{attribute_namespace ? "#{attribute_namespace}:" : ""}#{attribute.tag}", value ]
      else
        []
      end
      
    end.flatten
    
    attributes = Hash[ *attributes ]

    #
    # Create a tag in the builder that matches the class's tag name and append
    # any attributes to the element that were defined above.
    #
    builder.send(self.class.tag_name,attributes) do |xml|
      
      #
      # Add all the registered namespaces to the root element.
      # When this is called recurisvely by composed classes the namespaces
      # are still added to the root element
      #
      if self.class.instance_variable_get('@registered_namespaces') && builder.doc.root
        self.class.instance_variable_get('@registered_namespaces').each_pair do |name,href|
          builder.doc.root.add_namespace(name,href)
        end
      end
      
      #
      # If the object we are persisting has a namespace declaration we will want
      # to use that namespace or we will use the default namespace.
      # When neither are specifed we are simply using whatever is default to the
      # builder
      #
      if self.class.respond_to?(:namespace) && self.class.namespace
        xml.parent.namespace = builder.doc.root.namespace_definitions.find { |x| x.prefix == self.class.namespace }
      elsif default_namespace
        xml.parent.namespace = builder.doc.root.namespace_definitions.find { |x| x.prefix == default_namespace }
      end

      
      #
      # When a text_node has been defiend we add the resulting value
      # the output xml
      #
      if text_node = self.class.instance_variable_get('@text_node')
        text_accessor = text_node.tag || text_node.name
        value = send(text_accessor)
        
        if on_save_action = text_node.options[:on_save]
          if on_save_action.is_a?(Proc)
            value = on_save_action.call(value)
          elsif respond_to?(on_save_action)
            value = send(on_save_action,value)
          end
        end
        
        builder.text(value)
      end

      #
      # for every define element (i.e. has_one, has_many, element) we are
      # going to persist each one
      #
      self.class.elements.each do |element|

        tag = element.tag || element.name

        #
        # The value to store is the result of the method call to the element,
        # by default this is simply utilizing the attr_accessor defined. However,
        # this allows for this method to be overridden
        #
        value = send(element.name)

        #
        # If the element defines an on_save lambda/proc then we will call that
        # operation on the specified value. This allows for operations to be 
        # performed to convert the value to a specific value to be saved to the xml.
        #
        if on_save_action = element.options[:on_save]
          if on_save_action.is_a?(Proc)
            value = on_save_action.call(value)
          elsif respond_to?(on_save_action)
            value = send(on_save_action,value)
          end 
        end

        #
        # Normally a nil value would be ignored, however if specified then
        # an empty element will be written to the xml
        #
        if value.nil? && element.options[:single] && element.options[:state_when_nil]
          xml.send(tag,"")
        end
        
        #
        # To allow for us to treat both groups of items and singular items
        # equally we wrap the value and treat it as an array.
        #
        if value.nil?
          values = []
        elsif value.respond_to?(:to_ary) && !element.options[:single]
          values = value.to_ary
        else
          values = [value]
        end
        
        values.each do |item|

          if item.is_a?(HappyMapper)

            #
            # Other items are convertable to xml through the xml builder
            # process should have their contents retrieved and attached
            # to the builder structure
            #
            item.to_xml(xml,element.options[:namespace])

          elsif item
            
            item_namespace = element.options[:namespace] || default_namespace
            
            #
            # When a value exists we should append the value for the tag
            #
            if item_namespace
              xml[item_namespace].send(tag,item.to_s)
            else
              xml.send(tag,item.to_s)
            end

          else

            #
            # Normally a nil value would be ignored, however if specified then
            # an empty element will be written to the xml
            #
            xml.send(tag,"") if element.options[:state_when_nil]

          end

        end

      end

    end

    write_out_to_xml ? builder.to_xml : builder
    
  end
  
  
end

require 'happymapper/item'
require 'happymapper/attribute'
require 'happymapper/element'
require 'happymapper/text_node'
