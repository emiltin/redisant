class Index
  
  def initialize name, klass, options
    @name = name.to_s
    @class = klass
    @options = options
    @type = options[:type].to_s
    @order = @type=='alpha' ? 'alpha' : ''
    
    if @type=='time'
      @sort_key = "#{klass.name.downcase}:*:attributes->#{name}:float"
    else
      @sort_key = "#{klass.name.downcase}:*:attributes->#{name}"
    end
  end
  
  def list_key
    @list_key ||= "#{@class.name.downcase}:ids"
  end  

  def ids options={}
    options = { order: :asc, offset:0, limit:-1 }.merge options
    args = { limit: [options[:offset], options[:limit]] }
    if options[:order] == :asc
      list = $redis.sort list_key, args.merge( by:@sort_key, order:"#{@order} asc" )
    elsif options[:order] == :desc
      list = $redis.sort list_key, args.merge( by:@sort_key, order:"#{@order} desc" )
    else
      raise 'Invalid sort order'
    end
    
    list.map do |item|
      item.to_i
    end
  end

  def objects options={}
    ids(options).map do |id|
      @class.find id
    end    
  end
  
  def rebuild
  end
  
  private
  
  def item_value item
    "#{item.attribute(@name)}:#{item.id}"
  end 
end
