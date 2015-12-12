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
    $redis.sadd key(value), record.id.to_s
  end
  
  def update record, prev_value, cur_value
    if prev_value != cur_value
      remove record, prev_value
      add record, cur_value
    end
  end
  
  def remove record, value
    $redis.srem key(value), record.id.to_s
  end  

end
