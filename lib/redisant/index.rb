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
end
