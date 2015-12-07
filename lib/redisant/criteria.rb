class Criteria
  undef_method '=='
  undef_method '!='

  def initialize(klass)
    @klass = klass
  end

  def criteria
    @criteria ||= {:conditions => {}}
  end

  def where args
    criteria[:conditions].merge!(args)
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
    criteria[:conditions].merge!(attributes)
    criteria[:first] = true
    self
  end

  def last attributes={}
    criteria[:conditions].merge!(attributes)
    criteria[:last] = true
    self
  end

  def order options
    criteria[:order] = options
    self
  end

  def method_missing(*args, &block)
    load_if_needed
    @objects.send(*args, &block)
  end

  def reload!
    raise "Count and random cannot be combined" if criteria[:count] && criteria[:random]
    if criteria[:conditions] != {}
      load_where
    elsif criteria[:first]
      load_first
    elsif criteria[:last]
      load_last
    elsif criteria[:count]
      load_count
    elsif criteria[:random]
      load_random
    end
  end

  def loaded?
    @loaded == true
  end

  def result
    load_if_needed
    @objects
  end

  private

  def load_if_needed
    loaded = @loaded
    @loaded = true
    reload! unless loaded
  end

  def load_where
    if criteria[:order]
      # find
      if criteria[:conditions].keys.size > 1
        tmp = rand(36**16).to_s(36)
        Search.where @klass, criteria[:conditions], tmp
        del = true
      else
        key = criteria[:conditions].keys.first
        value = criteria[:conditions].values.first
        tmp = "#{@klass.name.downcase}:search:#{key}:#{value}"
      end
      
      # sort
      index = @klass.find_index criteria[:order][:sort].to_s
      if index
        ids = index.ids criteria[:order].merge(sort_key:tmp)
        @objects = ids.map { |t| t.to_i }
      end
      
      $redis.del tmp if del
      
    else
      @objects = Search.where @klass, criteria[:conditions]
    end
  
    #FIXME can we avoid loading all ids?
    if criteria[:count]
      @objects = @objects.size    
    elsif criteria[:first]
      load_object @objects.first
    elsif criteria[:last]
      load_object @objects.last
    elsif criteria[:random]
      load_object @objects.sample 
    end
  end

  def load_first
    load_object $redis.zrange(@klass.class_key('ids'), 0, 0).first
  end

  def load_last
    load_object $redis.zrange(@klass.class_key('ids'), -1, -1).first
  end

  def load_count
    @objects = $redis.zcount @klass.class_key('ids'), '-inf', '+inf'
  end

  def load_random
    key = @klass.class_key('ids')
    n = $redis.zcount key, '-inf', '+inf'
    i = rand n
    load_object $redis.zrange( key, i, i ).first.to_i
  end

  def load_object id
    return unless id
    t = @klass.new id:id.to_i
    t.load
    @objects = t
  end

end
