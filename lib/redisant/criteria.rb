class Criteria
  undef_method '=='
  undef_method '!='

  def initialize(klass)
    @klass = klass
  end

  def criteria
    @criteria ||= {:where => {}}
  end

  def where args
    criteria[:where].merge!(args)
    self
  end

  def limit limit
    criteria[:limit] = limit
    self
  end

  def count
    criteria[:count] = true
    self
  end

  def random
    criteria[:random] = true
    self
  end

  def first attributes={}
    criteria[:where].merge!(attributes)
    criteria[:offset] = 0
    criteria[:limit] = 1
    criteria[:order] = :asc
    self
  end

  def last attributes={}
    criteria[:where].merge!(attributes)
    criteria[:offset] = 0
    criteria[:limit] = 1
    criteria[:order] = :desc
    self
  end

  def sort options
    criteria[:sort] = options
    self
  end

  def order options
    criteria[:order] = options
    self
  end

  def ids
    criteria[:ids] = true
    self
  end
  

  def ids?
    criteria[:ids] == true
  end
  
  def where?
    criteria[:where].size > 0
  end
  
  def where_single?
    criteria[:where].size == 1
  end

  def where_multi?
    criteria[:where].size > 1
  end

  def single?
    criteria[:limit] == 1 ||
    criteria[:first] ||
    criteria[:last] ||
    criteria[:random] ||
    criteria[:count]
  end

  def sort?
    criteria[:sort] != nil
  end

  def order?
    criteria[:order] != nil
  end

  def limit?
    criteria[:limit] != nil
  end

  def count?
    criteria[:count] == true
  end

  def random?
    criteria[:random] == true
  end
  
  def object_class
    @klass
  end
  
  def get_conditions
    criteria[:where]
  end
  
  def get_order
    criteria[:order]
  end
  
  def method_missing(*args, &block)
    load_if_needed
    @result.send(*args, &block)
  end

  def load_if_needed
    loaded = @loaded
    @loaded = true
    reload! unless loaded
  end


  def loaded?
    @loaded == true
  end

  def result
    load_if_needed
    @result
  end

  def reload!
    @result = Query.new(self).run
  end
  
end
