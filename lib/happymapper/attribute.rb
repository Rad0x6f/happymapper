module HappyMapper
  class Attribute < Item
    attr_accessor :default
    attr_reader :has_default

    # @see Item#initialize
    # Additional options:
    #   :default => Object The default value for this
    def initialize(name, type, o={})
      super
      self.default = o[:default]
      @has_default = o.has_key? :default
    end

    def find(node, namespace, xpath_options)
      if options[:xpath]
        yield(node.xpath(HappyMapper::namespacify(options[:xpath], namespace),xpath_options))
      else
        yield(node[tag])
      end
    end
  end
end
