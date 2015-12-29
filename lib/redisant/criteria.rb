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

  def where options
    merge_options options
    self
  end

  def limit limit
    criteria[:limit] = limit
    self
  end

  def count
    criteria[:count] = true
    result
  end

  def random
    criteria[:random] = true
    result
  end

  def first options={}
    merge_options options
    criteria[:offset] = 0
    criteria[:limit] = 1
    criteria[:order] = :asc
    result
  end

  def last options={}
    merge_options options
    criteria[:offset] = 0
    criteria[:limit] = 1
    criteria[:order] = :desc
    result
  end

  def sort options
    criteria[:sort] = options
    self
  end

  def order options
    raise Redisant::InvalidArgument.new('Invalid order') unless ['asc','desc'].include? options.to_s
    
    criteria[:order] = options
    self
  end

  def ids
    criteria[:ids] = true
    self
  end
  
  def any?
    criteria[:exists] = true
    criteria[:ids] = true
    result
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
  
  private
 
  def merge_options options
    criteria[:where].merge!(options)
  end

end
