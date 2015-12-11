class Query

  def initialize criteria
    @criteria = criteria
  end

  def run
    raise "Count and random cannot be combined" if @criteria.count? && @criteria.random?

    use_sort = @criteria.sort? || @criteria.limit? || @criteria.single?
    count = @criteria.count?
    random = @criteria.random?
    if @criteria.where_multi?
      if use_sort
        if count
          return count_intersection
        elsif random
          return random_intersection
        else
          store_intersection
          @ids = fetch_with_sort
        end
      else
        if count
          return count_intersection
        elsif random
          return random_intersection
        else
          @ids = fetch_intersection
        end
      end
    elsif @criteria.where_single?
      use_where_single
      if count
        return count_set
      elsif random
        return random_set
      else
        @ids = fetch_with_sort
      end
    else
      use_ids
      if count
        return count_ids
      elsif random
        return random_ids
      else
        @ids = fetch_with_sort
      end
    end
    
    if @criteria.ids?
      flatten_single_items @ids
    else
      load_objects
      flatten_single_items @objects
    end
  ensure
    delete_tmp
  end

  private

  def flatten_single_items a
    if @criteria.single? && a.size == 1
      a.first
    else
      a
    end
  end

  def use_where_single
    key = @criteria.get_conditions.keys.first
    value = @criteria.get_conditions.values.first
    @set = Search.search_key @criteria.object_class, key, value
  end

  def use_ids
    @set = @criteria.object_class.class_key('ids')
  end

  def fetch_intersection
    Search.where @criteria.object_class, @criteria.get_conditions
  end


  def store_intersection
    # combine search sets to temporary set that we can sort later
    @set = "tmp:#{rand(36**16).to_s(36)}"
    Search.where @criteria.object_class, @criteria.get_conditions, @set
    @del = true
  end

  def delete_tmp
    $redis.del @set if @del
    @del = nil
  end

  def count_intersection
    Search.count @criteria.object_class, @criteria.get_conditions
  end

  def count_set
    $redis.scard @set
  end

  def fetch_with_sort
    want = [:sort,:offset,:limit,:order,:sort_type]
    args = @criteria.criteria.select { |k,v| want.include? k }
    args.merge!( class: @criteria.object_class, key: @set )
    Index.order args
  end


  def count_ids
    @result = $redis.zcount @criteria.object_class.class_key('ids'), '-inf', '+inf'
  end

  def random_ids
    i = rand count_ids
    $redis.zrange( @criteria.object_class.class_key('ids'), i, i ).first.to_i
  end

  def random_set
    $redis.srandmember(@set).to_i
  end

  def load_objects
    @objects = @ids.map { |id| @criteria.object_class.load id }
  end

end