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
  end
  
  describe "#attributes" do
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

  describe "#first" do
    it "should find the first item" do
      record1 = Record.build id:1
      record2 = Record.build id:2
      record3 = Record.build id:3
      item = Record.first
      expect(item).to be_a(Record)
      expect(item.id).to eq(record1.id)
    end
  end

  describe "#last" do
    it "should find the last item" do
      record1 = Record.build id:1
      record2 = Record.build id:2
      record3 = Record.build id:3
      item = Record.last
      expect(item).to be_a(Record)
      expect(item.id).to eq(record3.id)
    end
  end

  describe "#id" do
    it "should return all object ids" do
      n = 3
      n.times do |i|
        item = Record.build
      end
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
end