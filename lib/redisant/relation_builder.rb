module RelationBuilder
  def self.included(base)
    base.extend ClassMethods
  end

  def find_relation name, &block
    return unless name
    relation = relations[name.to_s]
    return relation if relation
    relations[name.to_s] = block.call if block
  end
  
  def relations
    @relations ||= {}
  end
     
  def setup_relations
    self.class.relation_definitions.each_pair do |name,klass|
      relations[name] = klass.new(name, self)
    end
  end 


  module ClassMethods
    def relation_definitions
      @relation_definitions ||= {}
    end
    
    def add_relation_definition name, klass
      raise Redisant::InvalidArgument.new("Relation #{name} already exists") if relation_definitions[name.to_s]
      relation_definitions[name.to_s] = klass
    end
    
    def has_many name
      add_relation_definition name, HasMany
      send :define_method, name do
        relation = find_relation(name) { HasMany.new(name, self) }
      end
    end

    def belongs_to name
      add_relation_definition name, BelongsTo
      send :define_method, name do
        relation = find_relation(name) { BelongsTo.new(name, self) }
        relation.owner
      end
      send :define_method, "#{name}=" do |item, reprocitate=true|
        relation = find_relation(name) { BelongsTo.new( name, self ) }
        relation.set_owner item, reprocitate
      end

    end
          
  end
end
