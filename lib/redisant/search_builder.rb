module SearchBuilder
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def finder name, options={}
      searches[name.to_s] ||= Search.new name, self, options
    end
    
    def find_search name
      searches[name.to_s]
    end

    def searches
      @searches ||= {}
    end

  end
  
end
