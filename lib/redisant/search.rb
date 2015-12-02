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
  
  def self.where klass, attributes
    keys = []
    attributes.each_pair do |k,v|
      keys << "#{klass.name.downcase}:search:#{k}:#{v}"
    end
    got = $redis.sinter(keys)
    got.map { |id| id.to_i }
  end
  
  private
  
  def item_value item
    "#{item.attribute(@name)}:#{item.id}"
  end 
end
