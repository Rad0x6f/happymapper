dir = File.dirname(__FILE__)
$:.unshift(dir) unless $:.include?(dir) || $:.include?(File.expand_path(dir))

require 'date'
require 'time'
require 'rubygems'

gem 'libxml-ruby', '>= 0.9.7'
require 'xml'
require 'libxml_ext/libxml_helper'


class Boolean; end

module HappyMapper
  
  def self.included(base)
    base.instance_variable_set("@attributes", {})
    base.instance_variable_set("@elements", {})
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
    
    def element(name, type, options={})
      element = Element.new(name, type, options)
      @elements[to_s] ||= []
      @elements[to_s] << element
      attr_accessor element.method_name.intern
    end
    
    def elements
      @elements[to_s] || []
    end
    
    def has_one(name, type, options={})
      element name, type, {:single => true}.merge(options)
    end
    
    def has_many(name, type, options={})
      element name, type, {:single => false}.merge(options)
    end
    
    def tag(new_tag_name)
      @tag_name = new_tag_name.to_s
    end
    
    def get_tag_name
      @tag_name ||= to_s.downcase
    end
    
    def parse(xml, o={})
      options = {
        :single => false,
        :from_root => false,
      }.merge(o)
      
      xpath, collection = '', []
      
      doc   = xml.is_a?(LibXML::XML::Node) ? xml : xml.to_libxml_doc
      node  = doc.respond_to?(:root) ? doc.root : doc
      
      # puts doc.inspect, doc.respond_to?(:root) ? doc.root.inspect : ''
      
      unless node.namespaces.default.nil?
        namespace = "default_ns:" 
        node.namespaces.default_prefix = namespace.chop
        # warn "Default XML namespace present -- results are unpredictable" 
      end
      
      if node.namespaces.to_a.size > 0 && namespace.nil? && !node.namespaces.namespace.nil?
        namespace = node.namespaces.namespace.prefix + ":" 
      end
      
      xpath += doc.respond_to?(:root) ? '' : '.'
      xpath += options[:from_root] ? '/' : '//'
      xpath += namespace  if namespace
      xpath += get_tag_name
      # puts "parse: #{xpath}"
      
      nodes = node.find(xpath)
      nodes.each do |node|
        obj = new
        
        attributes.each do |attr| 
          obj.send("#{attr.method_name}=", 
                    attr.from_xml_node(node))
        end
        
        elements.each do |elem|
          elem.namespace = namespace
          # puts "#{elem.method_name} - #{namespace} - #{elem.namespace}"
          obj.send("#{elem.method_name}=", 
                    elem.from_xml_node(node))
        end
        collection << obj
      end

      # per http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Document.html#M000354
      nodes = nil
      GC.start

      options[:single] ? collection.first : collection
    end
  end
end

require 'happymapper/item'
require 'happymapper/attribute'
require 'happymapper/element'
