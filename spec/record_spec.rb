require 'spec_helper'

class Animal < Record
  attribute :name
end


RSpec.describe Record do

  describe "#attribute" do
    it "should define setter and getter" do
      animal = Animal.new
      name = 'Tiger'
      animal.name = name
      expect(animal.name).to eq(name)
    end

    it "should accept attributes" do
      record = Record.new name:'bike', price:99
      expect(record.attribute(:id)).to eq(nil)
      expect(record.attribute(:name)).to eq('bike')
      expect(record.attribute(:price)).to eq(99)
    end

    it "should not store id in attributes" do
      record = Record.new id:5345, name:'bike'
      expect(record.attribute(:id)).to eq(nil)
      expect(record.attribute(:name)).to eq('bike')
    end

    it "should store and retreive Time objects" do
      record = Record.build alarm_at: Time.new(2015,12,7,12,34,57)
      record = Record.first
      expect(record.attribute(:alarm_at)).to be_a(Time)
      expect(record.attribute(:alarm_at)).to eq(Time.new(2015,12,7,12,34,57))
    end

    it "should store and retreive hashes" do
      record = Record.build
      record.update_attributes prices: {'hat'=>10, 'shoes'=>30}
      record = Record.first
      expect(record.attribute(:prices)).to eq({'hat'=>10, 'shoes'=>30})
    end
  end

  describe "#any?" do
    it "should be false if no records" do
      expect(Record.any?).to eq(false)
      record = Record.build
      expect(Record.any?).to eq(true)
      record.destroy
      expect(Record.any?).to eq(false)
    end
  end

  describe "#dirty?" do
    it "should be false for new records without attributes" do
      record = Record.new
      expect(record.dirty?).to eq(false)
    end

    it "should be true for new records with attributes" do
      record = Record.new name: 'Tiger'
      expect(record.dirty?).to eq(true)
    end

    it "should be true after setting attribute" do
      record = Record.new
      expect(record.dirty?).to eq(false)
      record.set_attribute :name, 'Tiger'
      expect(record.dirty?).to eq(true)      
    end

    it "should be true after setting attributes" do
      record = Record.new
      expect(record.dirty?).to eq(false)
      record.attributes = {name: 'Tiger'}
      expect(record.dirty?).to eq(true)      
    end

    it "should be false after saving" do
      record = Record.new name: 'Cat'
      expect(record.dirty?).to eq(true)
      record.save
      expect(record.dirty?).to eq(false)      
    end

    it "should be false after loading" do
      record = Record.new name: 'Cat'
      record.save
      record = Record.first
      expect(record.dirty?).to eq(false)      
    end

  end

  describe "#build" do
    it "should return record without id" do
      record = Record.build
      expect(record.id).to_not eq(nil)
    end

    it "should accept attributes" do
      record = Record.build name:'bike', price:99
      expect(record.id).to_not eq(nil)
      expect(record.attribute(:id)).to eq(nil)
      expect(record.attribute(:name)).to eq('bike')
      expect(record.attribute(:price)).to eq(99)
    end

    it "should not store id in attributes" do
      record = Record.build id:5345, name:'bike'
      expect(record.id).to_not eq(nil)
      expect(record.attribute(:id)).to eq(nil)
      expect(record.attribute(:name)).to eq('bike')
    end

  end

  describe "#count" do
    it "should return zero items when empty" do
      expect(Record.count).to eq(0)
    end

    it "should return the number of items" do
      n = 3
      n.times do |i|
        item = Record.build name: "item#{i}"
      end
      expect(Record.count).to eq(n)
    end
  end
  
  describe "#id" do
    it "should return nil if not saved" do
      item = Record.new
      expect(item.id).to eq(nil)
    end

    it "should start from 1 and be sequential" do
      1.upto(3) do |i|
        item = Record.build name: "item#{i}"
        expect(item.id).to eq(i)
      end
    end

    it "should return id set with new" do
      id = 83622
      item = Record.new id: id
      expect(item.id).to eq(id)
      item.save
      expect(item.id).to eq(id)
      
      load = Record.find id
      expect(load.id).to eq(id)      
    end

    it "should return id set with build" do
      id = 83622
      item = Record.build id: id
      expect(item.id).to eq(id)
      
      load = Record.find id
      expect(load.id).to eq(id)      
    end
    
    it "automatic ids should skip manual ids" do
      item_a = Record.build id: 2
      item_b = Record.build
      item_c = Record.build
      expect(item_a.id).to eq(2)      
      expect(item_b.id).to eq(1)
      expect(item_c.id).to eq(3)
    end
  end

  
  describe "#attributes" do
    it "should store/retrive data in memory" do
      attributes = { 
        'string' => 'Anna', 
        'int' => 18, 
        'float' => 78.23423, 
        'array' => ['running','climbing'],
        'hash' => {'red' => 5, 'blue' => 9, 'green' => -1}
      }
      item = Record.build attributes
      attributes.keys do |key|
        expect(item.attributes[key]).to eq(attributes[key])
      end
    end

    it "should save/load data to the db as strings" do
      attributes = { 
        'string' => 'Anna', 
        'int' => 18, 
        'float' => 78.23423, 
        'array' => ['running','climbing'],
        'hash' => {'red' => 5, 'blue' => 9, 'green' => -1}
      }
      item = Record.build attributes
      loaded = Record.find item.id
      attributes.keys do |key|
        expect(loaded.attributes[key]).to eq(attributes[key])
      end
    end
  end
  
  describe "#update_attributes" do
    it "should update specific attributes" do
      item = Record.build color:'purple', mood:'wonder' 
      item.update_attributes(mood:'surprise')

      item = Record.first
      expect(item.attributes).to eq({'color'=>'purple','mood'=>'surprise'})
    end

    it "should work with hashes" do
      item = Record.build 'size'=>8, 'fruits'=>{'banana'=>'yellow','apple'=>'green'}
      item.update_attributes('size'=>5)

      item = Record.first
      expect(item.attributes).to eq({'size'=>5, 'fruits'=>{'banana'=>'yellow','apple'=>'green'}})
    end

    it "should work with arrays" do
      item = Record.build 'size'=>3, 'fruits'=>['banana','apple','melons']
      item.update_attributes('fruits'=>['pears','cherries'])

      item = Record.first
      expect(item.attributes).to eq({'size'=>3, 'fruits'=>['pears','cherries']})
    end
  end

  
  describe "#find" do
    it "should find the correct item" do
      id_to_attribute = {}     
      1.upto(3) do |i|
        item = Record.build 'name'=>"item#{i}"
        id_to_attribute[item.id] = item.attributes
      end
      1.upto(3) do |i|
        item = Record.find i
        expect(id_to_attribute[item.id]).to eq(item.attributes)
      end
    end
  end

  describe "#id" do
    it "should return all object ids" do
      record1 = Record.build id:1
      record2 = Record.build id:2
      record3 = Record.build id:3
      ids = Record.ids
      expect(ids).to eq([1,2,3])
    end
  end

  describe "#all" do
    it "should return all objects" do
      n = 3
      n.times do |i|
        item = Record.build
      end
      all = Record.all
      classes = all.map { |item| item.class }
      ids = all.map { |item| item.id }
      expect(classes).to eq([Record,Record,Record])
      expect(ids).to eq([1,2,3])
    end
  end

  describe "#load_attributes" do
    it "should load all attributes if no keys specified" do
      record = Record.build id: 1, type: 'bike', color: 'green'

      record = Record.new id: 1
      expect(record.attributes).to eq({})

      record.load_attributes
      expect(record.attributes).to eq({'type'=>'bike', 'color'=>'green'})
    end

    it "should load all attributes if all keys specified" do
      record = Record.build id: 1, type: 'bike', color: 'green'

      record = Record.new id: 1
      expect(record.attributes).to eq({})

      record.load_attributes [:type, :color]
      expect(record.attributes).to eq({'type'=>'bike', 'color'=>'green'})
    end

    it "should load some attributes if keys specified" do
      record = Record.build id: 1, type: 'bike', color: 'green'

      record = Record.new id: 1
      expect(record.attributes).to eq({})

      record.load_attributes [:type]
      expect(record.attributes).to eq({'type'=>'bike'})
    end

    it "should return nil for non-existing keys" do
      record = Record.build id: 1, type: 'bike', color: 'green'

      record = Record.new id: 1
      expect(record.attributes).to eq({})

      record.load_attributes [:color, :bingo]
      expect(record.attributes).to eq({'color'=>'green', 'bingo'=>nil})
    end

    it "should resave only loaded attributes" do
      record = Record.build id: 1, type: 'bike', color: 'green'

      record = Record.new id: 1
      expect(record.attributes).to eq({})

      record.load_attributes [:color]
      expect(record.attributes).to eq({'color'=>'green'})

      record.set_attribute :color, 'red'
      record.save

      record = Record.find 1
      expect(record.attributes).to eq({'type'=>'bike','color'=>'red'})
    end
  end
end