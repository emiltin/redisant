class Query

  def initialize criteria
    @criteria = criteria
  end

  def run
    raise "Count and random cannot be combined" if @criteria.count? && @criteria.random?
    
    collect_keys
    if @criteria.count?
      count
    elsif @criteria.random?
      random
    else
      fetch
    end
  ensure
    delete_tmp
  end

  private


  def collect_keys
    @sub_keys = []
    # start from a has_many relation?
    @sub_keys << @criteria.ids_key if @criteria.get_relation || @criteria.get_conditions.empty?
    
    # where conditions
    name = @criteria.object_class.name.downcase
    @criteria.get_conditions.each_pair do |k,v|
      @sub_keys << "#{name}:search:#{k}:#{v}"
    end
    
    @final_key = @sub_keys.first if @sub_keys.size == 1
  end
  
  def count
    if @sub_keys.size > 1
      count_intersection
    else
      count_ids
    end
  end

  def random
    if @sub_keys.size > 1
      random_intersection
    else
      random_ids
    end
  end

  def fetch
    if @sub_keys.size > 1
      if @criteria.sort? || @criteria.limit? || @criteria.single?
        store_intersection
        @ids = sort_and_limit
      else
        @ids = fetch_intersection
      end
    else
      @final_key = @sub_keys.first
      @ids = sort_and_limit
    end
    
    if @criteria.ids?
      flatten_single_items @ids
    else
      load_objects
      flatten_single_items @objects
    end
  end

  def flatten_single_items a
    if @criteria.single? && a.size == 1
      a.first
    else
      a
    end
  end

  def fetch_intersection
    got = $redis.sinter @sub_keys
    got.map { |id| id.to_i } if got
  end

  def store_intersection
    # combine search sets to temporary set that we can sort later
    @final_key = "tmp:#{rand(36**16).to_s(36)}"
    $redis.sinterstore @final_key, @sub_keys
    @del = true
  end
    
  def delete_tmp
    $redis.del @final_key if @del
    @del = nil
  end
  
  def random_intersection
    # random numbers in redis lua scripts must be seeded with an outside integer
    lua = "
    math.randomseed(tonumber(ARGV[1]))
    local ids=redis.call('SINTER', unpack(KEYS))
    return ids[ math.random(#ids) ]
    "
    $redis.eval(lua, @sub_keys, [rand(2**32)]).to_i
  end

  def count_intersection
    lua = "return #redis.call('SINTER', unpack(KEYS));"
    $redis.eval lua, @sub_keys
  end

  def count_set
    $redis.scard @final_key
  end

  def sort_and_limit
    criteria = @criteria.criteria
    
    sort = criteria[:sort]
    order = criteria[:order].to_s || 'asc'
    
    if criteria[:limit]
      limit = [criteria[:offset] || 0, criteria[:limit]]
    end
    
    if sort
      index = @criteria.object_class.find_index(sort)
      type = index.type
      by = "#{@criteria.object_class.name.downcase}:*:attributes->#{sort}"
      by << ":float" if type == 'float'
      if type == 'string'
        order << ' alpha'
      end
    else
      by = 'nosort' unless criteria[:limit]==1
    end
    
    args = { limit: limit, by: by, order: order }
    ids = $redis.sort @final_key, args
    ids.map! { |t| t.to_i } if ids
  end

  def count_ids
    @result = $redis.scard @final_key
  end

  def random_ids
    $redis.srandmember(@final_key).to_i
  end

  def random_set
    $redis.srandmember(@final_key).to_i
  end

  def load_objects
    @objects = @ids.map { |id| @criteria.object_class.load id }
  end

end