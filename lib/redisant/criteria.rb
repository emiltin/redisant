class Criteria
  undef_method '=='
  undef_method '!='
  
  attr_reader :object_class, :ids_key
  
  def initialize base
    if base.is_a? Relation
      @ids_key = base.redis_key
      @object_class = base.object_class
      criteria[:relation] = base
    else
      @ids_key = base.id_key
      @object_class = base
    end
  end

  def relation relation
    criteria[:relation] = relation
    self
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
    num_conditions == 1
  end

  def where_multi?
    num_conditions >= 1
  end

  def single?
    criteria[:limit] == 1 ||
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
  
  def num_conditions
    n = criteria[:where].keys.size
    if criteria[:relation]
      n += 1
    end
    n
  end
  
  def get_conditions
    criteria[:where]
  end

  def get_relation
    criteria[:relation]
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
