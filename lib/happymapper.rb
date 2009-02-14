dir = File.dirname(__FILE__)
$:.unshift(dir) unless $:.include?(dir) || $:.include?(File.expand_path(dir))

require 'date'
require 'time'
require 'rubygems'
gem 'libxml-ruby', '= 0.9.8'
require 'xml'

class Boolean; end

module HappyMapper

  DEFAULT_NS = "happymapper"

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

      if xml.is_a?(XML::Node)
        node = xml
      else
        if xml.is_a?(XML::Document)
          node = xml.root
        else
          node = XML::Parser.string(xml).parse.root
        end

        root = node.name == tag_name
      end

      # This is the entry point into the parsing pipeline, so the default
      # namespace prefix registered here will propagate down
      namespaces = node.namespaces
      if namespaces && namespaces.default
        # don't assign the default_prefix if it has already been assigned
        namespaces.default_prefix = DEFAULT_NS unless namespaces.find_by_prefix(DEFAULT_NS)
        namespace ||= DEFAULT_NS
      end

      xpath = root ? '/' : './/'
      xpath += "#{namespace}:" if namespace
      #puts "parse: #{xpath}"

      nodes = []
      # when finding nodes, do it in this order:
      # 1. specified tag
      # 2. name of element
      # 3. tag_name (derived from class name by default)
      [options[:tag], options[:name], tag_name].compact.each do |xpath_ext|
        nodes = node.find(xpath + xpath_ext.to_s)
        break if nodes && nodes.size > 0
      end
      collection = nodes.collect do |n|
        obj = new

        attributes.each do |attr|
          obj.send("#{attr.method_name}=",
                    attr.from_xml_node(n, namespace))
        end

        elements.each do |elem|
          obj.send("#{elem.method_name}=",
                    elem.from_xml_node(n, namespace))
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
end

require 'happymapper/item'
require 'happymapper/attribute'
require 'happymapper/element'
