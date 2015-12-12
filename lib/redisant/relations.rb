class Relation
  attr_reader :name, :object
  
  def initialize name, object
    @name = name.to_s
    @object = object
    @class = Inflector.constantize Inflector.singularize(name)
  end
  
  def object_class
    @class
  end
end

class BelongsTo < Relation
  
  def initialize name, object
    super name, object
    @reverse_name = Inflector.pluralize @object.class.name.downcase
  end
  
  def destroy
    set_owner nil, true
  end
  
  # keys
  def redis_key
    raise Redisant::InvalidArgument.new('Cannot make key without id') unless @object && @object.id
    "#{@object.class_name}:#{@object.id}:belongs_to:#{@name}"
  end

  # query
  def owner_id
    @owner_id ||= $redis.get redis_key
  end

  def owner
    @owner ||= @class.find(owner_id) if owner_id
  end

  def set_owner item, reprocitate=true
    if owner
      if owner.respond_to? @reverse_name
        owner.send(@reverse_name).remove @object, false if reprocitate
      end
    end
    if item
      raise Redisant::InvalidArgument.new('Wrong object type') unless item.class_name == @name
      raise Redisant::InvalidArgument.new('Missing id') unless item.id
      $redis.set redis_key, item.id
      @owner = item
      @owner_id = item.id
      if owner.respond_to? @reverse_name
        owner.send(@reverse_name).add @object, false if reprocitate
      end
    else
      $redis.del redis_key
      @owner_id = nil
      @owner = nil
    end
  end
  
end

class HasMany < Relation
  
  def initialize name, object
    super name, object
    @reverse_name = @object.class.name.downcase
  end
  
  def destroy
    all.each do |item|
      item.send("#{@reverse_name}=", nil, true)
    end
    $redis.del redis_key
  end
  
  # keys
  def redis_key
    raise Redisant::InvalidArgument.new('Cannot make key without id') unless @object && @object.id
    "#{@object.class_name}:#{@object.id}:has_many:#{@name}"
  end

  # query
  def ids
    Criteria.new(self).ids
  end
  
  def count
    Criteria.new(self).count
  end

  def where attributes
    Criteria.new(self).where(attributes)
  end

  def first attributes={}
    Criteria.new(self).first attributes
  end

  def last attributes={}
    Criteria.new(self).last attributes
  end

  def sort options
    Criteria.new(self).sort options
  end

  def order options
    Criteria.new(self).order options
  end

  def random
    Criteria.new(self).random
  end

  def build options={}
    item = @class.new options
    item.save
    add_item item
    item
  end
    
  def add item, reprocitate=true
    if item.is_a? Array
      item.each { |i| add_item i }
    else
      add_item item
    end
  end
  
  def << object, reprocitate=true
    add object, reprocitate
  end

  def remove item, reprocitate=true
    return unless item
    if item.is_a? Array
      item.each {|i| remove_item i }
    else
      remove_item item
    end
  end

  def remove_all reprocitate=true
    $redis.del redis_key
    dirty
  end

  def all
    @objects ||= ids.map { |id| @class.find id }
  end
  
  
  private
  
  def dirty
    @ids = nil
    @count = nil
    @objects = nil
  end

  def add_item item, reprocitate=true
    return unless item
    raise Redisant::InvalidArgument.new("Wrong object type, expected #{@class.name}, got #{item.class}") unless item.is_a? Record
    raise Redisant::InvalidArgument.new("Wrong object type, expected #{@class.name}, got #{item.class}") unless item.class == @class
    $redis.sadd redis_key, item.id
    dirty
    #update reverse relation
    if reprocitate
      if item.respond_to? @reverse_name
        current_owner = item.send(@reverse_name)
        current_has_many = current_owner.send(@name) if current_owner
        if current_has_many && current_has_many != self
          current_has_many.remove( item, false )
        end
        item.send("#{@reverse_name}=", @object, false )
      end
    end
  end
  
  def remove_item item, reprocitate=true
    if item.is_a? Integer
      id = item
    else
      klass = Inflector.pluralize(item.class_name)
      raise Redisant::InvalidArgument.new("Wrong object type, expected #{@name}, got #{klass}") unless klass == @name
      id = item.id
    end
    $redis.srem redis_key, id
    dirty
    #update reverse relation
    if reprocitate
      if item.respond_to? "#{@reverse_name}="
        item.send("#{@reverse_name}=", nil, false )
      end
    end
  end
  
end
