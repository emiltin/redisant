class Search
  
  attr_reader :name, :class, :options, :type, :order
  def initialize name, klass, options
    @name = name.to_s
    @class = klass
    @options = options
  end
  
  def key value
    "#{@class.name.downcase}:search:#{@name}:#{value}"
  end  

  def add record, value
#    puts "add: #{@name} = #{value}"
    $redis.sadd key(value), record.id.to_s
  end
  
  def update record, prev_value, cur_value
    if prev_value != cur_value
#    puts "update: #{@name} = #{prev_value} -> #{cur_value}"
      remove record, prev_value
      add record, cur_value
    end
  end
  
  def remove record, value
#    puts "remove: #{@name} = #{value}"
    $redis.srem key(value), record.id.to_s
  end
  
  
  def self.search_key klass,k,v
    "#{klass.name.downcase}:search:#{k}:#{v}"
  end

  def self.where klass, attributes, store=nil
    keys = []
    attributes.each_pair do |k,v|
      keys << "#{klass.name.downcase}:search:#{k}:#{v}"
    end
    if store
      $redis.sinterstore(store, keys)
    else
      got = $redis.sinter(keys)
      got.map { |id| id.to_i } if got
    end
  end

  def self.count klass, attributes
    keys = []
    attributes.each_pair do |k,v|
      keys << "#{klass.name.downcase}:search:#{k}:#{v}"
    end
    lua = "return #redis.call('SINTER', unpack(KEYS));"
    $redis.eval lua, keys
  end
  
  

end
