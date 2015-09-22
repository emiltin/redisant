module IndexBuilder
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def index name, options={}
      indexes[name.to_s] ||= Index.new name, self, options
    end
    
    def find_index name
      indexes[name.to_s]
    end

    def indexes
      @indexes ||= {}
    end

  end
  
end
