require 'set'
require 'json'

class Record
  include AttributeBuilder
  include RelationBuilder
  include IndexBuilder
  
  attr_reader :id
  attr_reader :attributes

  def initialize attributes=nil
    raise 'Wrong arguments' unless attributes==nil or attributes.is_a? Hash
    @id = attributes.delete(:id) if attributes
    @attributes = stringify_attributes(attributes) || {}
    setup_relations if respond_to? :setup_relations
    @dirty = attributes != nil
    @id_saved = false
  end

  def class_name
    self.class.name.downcase
  end

  # query
  def self.find id
    raise "Invalid argument" unless id
    return nil unless exists? id
    t = self.new id:id
    
    t.load
    t
  end

  def self.find! id
    raise "Not found" unless exists? id
    t = self.new id:id
    t.load
    t
  end

  def self.exists? id
    $redis.zscore( class_key('ids'), id ) != nil
  end

  def self.all options={}
    sort = options.delete :sort
    if sort
      index = self.find_index sort.to_s
      raise "Cannot order by #{sort}" unless index
      index.objects options
    else
      ids.map { |id| self.find id }
    end
  end

  def self.first
    id = $redis.zrange(class_key('ids'), 0, 0).first
    if id
      t = self.new id:id.to_i
      t.load
      t
    end
  end

  def self.last
    id = $redis.zrange(class_key('ids'), -1, -1).first
    if id
      t = self.new id:id.to_i
      t.load
      t
    end
  end

  def self.count
    $redis.zcount class_key('ids'), '-inf', '+inf'
  end
  
  # dirty
  def dirty?
    @dirty
  end
  
  def dirty
    @dirty = true
  end
  
  # crud
  def self.build attributes=nil
    object = self.new attributes
    object.save
    object
  end
  
  def destroy
    destroy_relations
    destroy_attributes
    remove_id
  end
  
  def new?
    id == nil
  end

  def load
    load_attributes
    @id_saved = true
  end

  def save
    make_unique_id
    add_id
    save_attributes
    true
  end

  def self.destroy_all
    attribute_keys = ids.map {|id| "#{self.name.downcase}:#{id}:attributes" }
    $redis.multi do |multi|
      multi.del( attribute_keys )
      multi.del class_key('ids') 
      multi.del class_key('ids:counter')
    end
  end
  
  # keys
  def member_key str
    raise 'Cannot make key without id' unless @id
    "#{class_name}:#{@id}:#{str}"
  end

  def self.class_key str
    "#{self.name.downcase}:#{str}"
  end

  # single attribute
  def attribute key
    @attributes[key.to_s]
  end

  def set_attribute key, value
    @attributes[key.to_s] = value
    @dirty = true
  end
  
  def update_attribute key, value
    set_attribute key, value
    $redis.hset member_key('attributes'), key, value
  end

  # all attributes
  def attributes= attributes
    raise "Invalid arguments" unless attributes.is_a? Hash
    @attributes = stringify_attributes attributes
    @dirty = true
  end
  
  def load_attributes
    @attributes = decode_attributes $redis.hgetall(member_key('attributes'))
    @dirty = false
  end

  def save_attributes
    if @attributes.any? && dirty?
      synthesize_attributes
      $redis.hmset member_key('attributes'), encode_attributes
      @dirty = false
    end
  end
  
  def update_attributes attributes
    @attributes = stringify_attributes attributes
    save_attributes
  end

  def destroy_attributes
    $redis.del member_key('attributes')
    @attributes = nil
    @dirty = false
  end

  def cleanup_attributes
    # delete attribues in the hash that's not in our local attributes
    keys = $redis.hkeys member_key('attributes')
    delete = keys - @attributes.keys
    $redis.hdel member_key('attributes'), delete
  end

  # ids
  def make_unique_id
    return if @id
    #use optimistic concurrency control:
    #if id is taken, try again until we succeed
    while true
      id = $redis.incr(self.class.class_key('ids:counter')).to_i
      unless self.class.exists? id
        @id = id
        return
      end
    end
  end

  def self.ids options={}
    sort = options.delete :sort
    if sort
      index = self.find_index sort.to_s
      raise "Cannot order by #{sort}" unless index
      index.ids options
    else
      options = {order: :asc}.merge options
      if options[:order] == :asc
        $redis.zrange( class_key('ids'), 0, -1 ).map { |id| id.to_i }
      elsif options[:order] == :desc
        $redis.zrevrange( class_key('ids'), 0, -1 ).map { |id| id.to_i }
      else
        raise "Invalid order"
      end
    end
  end

  def add_id
    raise 'Cannot add empty id' unless @id
    return if @id_saved
    $redis.zadd self.class.class_key('ids'), @id.to_i, @id
    @id_saved = true
  end

  def remove_id
    raise 'Cannot remove empty id' unless @id
    $redis.zrem self.class.class_key('ids'), @id
    @id = nil
    @id_saved = false
  end

  
  private
    
  # add converted version of attributes which can later be used for sorting
  def synthesize_attributes
    synthesized = {}
    @attributes.each_pair do |k,v|
      if v.is_a? Time
        synthesized["#{k}:float"] = v.to_f     # convert time to number of seconds as float
      end
    end
    @attributes.merge! synthesized
  end
 
  def encode_attributes
    @attributes.collect do |k,v|
      [k.to_s,v.to_json]
    end.flatten
  end

  def decode_attributes attributes
    decoded = {}
    attributes.each do |pair|
      decoded[pair[0]] = JSON.parse pair[1], quirks_mode: true
    end
    @attributes = decoded
  end
  
  def destroy_relations
    relations.values.each {|relation| relation.destroy }
    @relations = nil
  end
  
  def stringify_attributes attributes
    attributes.collect {|k,v| [k.to_s,v] }.to_h if attributes
  end
  
end
