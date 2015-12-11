require 'set'
require 'json'
require 'time'

class Record
  include AttributeBuilder
  include RelationBuilder
  include IndexBuilder
  include SearchBuilder
  
  attr_reader :id
  attr_reader :attributes

  def initialize attributes=nil
    raise Redisant::InvalidArgument.new('Wrong arguments') unless attributes==nil or attributes.is_a? Hash
    @id = attributes.delete(:id) if attributes
    @attributes = stringify_attributes(attributes) || {}
    @prev_attributes = {}
    setup_relations if respond_to? :setup_relations
    @dirty = attributes != nil
    @id_saved = false
  end

  def class_name
    self.class.name.downcase
  end
  
  def self.load id
    t = self.new id:id
    t.load
    t
  end
  
  # query
  def self.find id
    raise Redisant::InvalidArgument.new("Invalid argument") unless id
    return nil unless exists? id
    t = self.new id:id
    
    t.load
    t
  end

  def self.find! id
    raise Redisant::InvalidArgument.new("Not found") unless exists? id
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
      raise Redisant::InvalidArgument.new("Cannot order by #{sort}") unless index
      index.objects options
    else
      ids.map { |id| self.find id }
    end
  end

  def self.first attributes={}
    Criteria.new(self).first attributes
  end

  def self.last attributes={}
    Criteria.new(self).last attributes
  end
  
  def self.random
    Criteria.new(self).random
  end

  def self.where attributes
    Criteria.new(self).where attributes
  end

  def self.count
    Criteria.new(self).count
  end

  def self.sort options
    Criteria.new(self).sort options
  end

  def self.order options
    Criteria.new(self).order options
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
    raise Redisant::InvalidArgument.new('Cannot make key without id') unless @id
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
    update_search
  end

  # all attributes
  def attributes= attributes
    raise Redisant::InvalidArgument.new("Invalid arguments") unless attributes.is_a? Hash
    @attributes = stringify_attributes attributes
    @dirty = true
  end
  
  def load_attributes
    decoded = decode_attributes($redis.hgetall(member_key('attributes')))
    @attributes = restore_attribute_types decoded
    @dirty = false
    keep_attributes
  end

  def save_attributes
    if @attributes.any? && dirty?
      synthesize_attributes
      $redis.hmset member_key('attributes'), encode_attributes
      @dirty = false
    end
    update_search
  end
  
  def update_attributes attributes
    @attributes = stringify_attributes attributes
    save_attributes
  end

  def destroy_attributes
    $redis.del member_key('attributes')
    @attributes = nil
    @dirty = false
    update_search
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

  def self.ids
    Criteria.new(self).ids
  end

  def add_id
    raise Redisant::InvalidArgument.new('Cannot add empty id') unless @id
    return if @id_saved
    $redis.zadd self.class.class_key('ids'), @id.to_i, @id
    @id_saved = true
  end

  def remove_id
    raise Redisant::InvalidArgument.new('Cannot remove empty id') unless @id
    $redis.zrem self.class.class_key('ids'), @id
    @id = nil
    @id_saved = false
  end

  
  private

  # redis can only sort by string or float
  # to sort by eg. Time we store float version of required attributes
  def synthesize_attributes
    synthesized = {}
    self.class.indexes.each_pair do |name,index|
      if index.type=='float'
         # for Time objects to_f return number of seconds since epoch
        @attributes["#{name}:float"] = @attributes[name].to_f
      end
    end
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
  
  def restore_attribute_types attributes
    restored = {}
    attributes.each_pair do |k,v|
      time_match = /(.+)_at$/.match k
      if time_match
        restored[k] = Time.parse v
      end
    end
    attributes.merge! restored
  end
  
  def destroy_relations
    relations.values.each {|relation| relation.destroy }
    @relations = nil
  end
  
  def stringify_attributes attributes
    attributes.collect {|k,v| [k.to_s,v] }.to_h if attributes
  end

  def keep_attributes
    if @attributes
      @prev_attributes = @attributes.dup
    else
      @prev_attributes = nil
    end
  end

  # search
  def update_search
    prev_keys = @prev_attributes ? @prev_attributes.keys : []
    cur_keys = @attributes? @attributes.keys : []
    keys = prev_keys | cur_keys
    keys = keys & self.class.searches.keys    # only attributes with search activated
    keys.each do |k|
      prev = @prev_attributes? @prev_attributes[k] : nil
      cur = @attributes ? @attributes[k] : nil
      if prev != cur
        search = self.class.find_search k.to_s
        if search
          if prev && cur
            search.update self, prev, cur
          elsif cur
            search.add self, cur
          elsif prev
            search.remove self, prev
          end
        end
      end
    end
    keep_attributes
  end

end
