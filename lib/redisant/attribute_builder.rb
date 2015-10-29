module AttributeBuilder
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def attribute name, options={}
      attributes[name.to_s] = options

      if options[:index]
        index name, type: options[:index]   # add index for attribute
      end

      send :define_method, name.to_s do
        attribute(name.to_s)
      end

      send :define_method, "#{name.to_s}=" do |value|
        set_attribute(name.to_s, value)
      end

    end
    
    def find_attribute name
      indexes[name.to_s]
    end

    def attributes
      @attributes ||= {}
    end

  end
  
end
