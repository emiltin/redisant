class Index
  
  attr_reader :name, :class, :options, :type, :order
  def initialize name, klass, options
    @name = name.to_s
    @class = klass
    @options = options
    @type = options[:type].to_s
    
    if @type=='float'
      @order = ''
      @sort_key = "#{klass.name.downcase}:*:attributes->#{name}:float"
    elsif @type=='string'
      @order = 'alpha'
      @sort_key = "#{klass.name.downcase}:*:attributes->#{name}"
    else
      raise Redisant::InvalidArgument.new 'Invalid index type'
    end
  end
  
  def list_key
    @list_key ||= "#{@class.name.downcase}:ids"
  end  

  def ids options={}
    key = options.delete(:sort_key) || list_key
    options = { order: :asc, offset:0, limit:-1 }.merge options
    args = { limit: [options[:offset], options[:limit]], by: @sort_key }
    if options[:order] == :asc
      args.merge! order:"#{@order} asc"
    elsif options[:order] == :desc
      args.merge! order:"#{@order} desc"
    else
      raise Redisant::InvalidArgument.new 'Invalid sort order'
    end
    ids = $redis.sort(key, args)
    ids.map { |t| t.to_i } if ids
  end

  def objects options={}
    ids(options).map do |id|
      @class.find id
    end    
  end
  
  private
  
  def item_value item
    "#{item.attribute(@name)}:#{item.id}"
  end


  def self.order options
    sort = options[:sort]
    klass = options[:class]
    key = options[:key] || "#{klass.name.downcase}:ids"
    limit = [options[:offset] || 0, options[:limit]] if options[:limit]
    order = options[:order].to_s || 'asc'
    index = klass.find_index(sort)
    if index
      type = klass.find_index(sort).type
    end
    
    if sort
      by = "#{klass.name.downcase}:*:attributes->#{sort}"
        by << ":float" if type == 'float'
    else
      by = 'nosort' unless options[:limit]==1
    end
    
    if type == 'string'
      order << ' alpha'
    end
    args = { limit: limit, by: by, order: order }
    ids = $redis.sort key, args
    if ids
     ids.map! { |t| t.to_i } 
   end
  end

end
