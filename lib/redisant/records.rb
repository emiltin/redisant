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
  attr_reader :dirty
  attr_reader :errors

  def initialize attributes=nil
    raise Redisant::InvalidArgument.new('Wrong arguments') unless attributes==nil or attributes.is_a? Hash
    @id = attributes.delete(:id) if attributes
    @attributes = stringify_attributes(attributes) || {}
    @prev_attributes = {}
    @dirty = @attributes.keys
    setup_relations if respond_to? :setup_relations
    @id_saved = false
    @errors = nil
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
    $redis.sismember( id_key, id )
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

  def self.any?
    $redis.scard( id_key ) > 0
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
    @dirty.any?
  end

  def dirty keys
    @dirty = @dirty | [keys].flatten
  end

  def clean
    @dirty = []
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
    return false unless validate
    make_unique_id
    add_id
    save_attributes
    true
  end

  def save!
    raise Redisant::ValidationFailed.new('Validation failed') unless save
  end

  def validate
    @errors = nil
    self.class.attributes.each_pair do |key,options|
      v = attribute(key)
      if options[:required]
        if v==nil
          @errors ||= {}
          @errors[key] = "is required"
        end
      end
      if v && options[:unique]
        conditions = {}
        conditions[key] = v
        if self.class.where(conditions).count > 0
          @errors ||= {}
          @errors[key] = "must be unique"
        end
      end
    end
    @errors == nil
  end

  def self.destroy_all
    keys = ids.map {|id| "#{self.name.downcase}:#{id}:attributes" }
    keys << id_key
    keys << class_key('ids:counter')
    $redis.del keys if keys.any?
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
    if value != @attributes[key.to_s]
      @attributes[key.to_s] = value
      dirty [key]
    end
  end
  
  def update_attribute key, value
    if value != @attributes[key.to_s]
      @attributes[key.to_s] = value
      $redis.hset member_key('attributes'), key, value
      update_search
    end
  end

  # multiple attributes
  def attributes= attributes
    raise Redisant::InvalidArgument.new("Invalid arguments") unless attributes.is_a? Hash
    attributes.each_pair do |key,value|
      if value != @attributes[key.to_s]
        @attributes[key.to_s] = value
        dirty key
      end
    end
  end
  
  def load_attributes keys=nil
    if keys
      keys = keys.map { |key| key.to_s }
      values = $redis.hmget(member_key('attributes'), keys)
      raw = keys.zip(values).to_h
    else
      raw = $redis.hgetall(member_key('attributes'))
    end
    decoded = decode_attributes(raw)
    @attributes = restore_attribute_types decoded
    keep_attributes
  end

  def save_attributes
    if dirty?
      synthesize_attributes
      $redis.hmset member_key('attributes'), encode_attributes
      clean
    end
    update_search
  end
  
  def update_attributes attributes
    raise Redisant::InvalidArgument.new("Invalid arguments") unless attributes.is_a? Hash
    @attributes.merge! stringify_attributes(attributes)
    dirty attributes.keys
    save_attributes
  end

  def destroy_attributes
    $redis.del member_key('attributes')
    @attributes = nil
    update_search
  end

  def cleanup_attributes
    # delete attribues in the hash that's not in our local attributes
    keys = $redis.hkeys member_key('attributes')
    delete = keys - @attributes.keys
    $redis.hdel member_key('attributes'), delete
  end

  # ids
  def self.id_key
    class_key 'id'
  end

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
    $redis.sadd self.class.id_key, @id.to_i
    @id_saved = true
  end

  def remove_id
    raise Redisant::InvalidArgument.new('Cannot remove empty id') unless @id
    $redis.srem self.class.id_key, @id
    @id = nil
    @id_saved = false
  end

  
  private
  
  # redis can only sort by string or float
  # to sort by eg. Time we store float version of required attributes
  def synthesize_attributes
    synthesized = {}
    self.class.indexes.each_pair do |name,index|
      if @dirty.include? name
        if index.type=='float'
          # for Time objects to_f return number of seconds since epoch
          key = "#{name}:float"
          value = @attributes[name].to_f
          @attributes[key] = value
          dirty key
        end
      end
    end
  end
 
  def encode_attributes
    encoded = {}
    @dirty.each do |key|
      k = key.to_s
      encoded[k] = @attributes[k].to_json
    end
    encoded.flatten
  end

  def decode_attributes attributes
    decoded = {}
    attributes.each do |pair|
      if pair[1]==nil
        decoded[pair[0]] = nil
      else
        decoded[pair[0]] = JSON.parse pair[1], quirks_mode: true
      end
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
