require 'spec_helper'

class Boat < Record
  has_many :sails
  attribute :type, index: :string, search: true
  attribute :color, index: :string, search: true
  attribute :owner, index: :string, search: true
  attribute :size
end

class Sail < Record
  belongs_to :boat
  attribute :type, index: :string, search: true
  attribute :color, index: :string, search: true
end


RSpec.describe Record do

  describe "#where" do
    it "should find objects by single attribute" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'

      expect(Boat.where(type:'ferry').ids).to eq([1])
      expect(Boat.where(type:'yacht').ids).to eq([2,3])
      expect(Boat.where(type:'raft').ids).to eq([])

      expect(Boat.where(color:'white').ids).to eq([1,2])
      expect(Boat.where(color:'blue').ids).to eq([3])
      expect(Boat.where(color:'red').ids).to eq([])
    end
  end

  describe "#where" do
    it "should return on array-like object" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'

      expect(Boat.where(type:'yacht').ids).to eq([2,3])

      expect(Boat.where(color:'white').ids).to eq([1,2])

      expect(Boat.where(type:'yacht').ids.size).to eq(2)
    end
  end

  describe "#where" do
    it "should be chainable" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'

      expect(Boat.where(type:'ferry').where(color:'white').ids.result).to eq([1])
      expect(Boat.where(type:'ferry').where(color:'blue').ids).to eq([])
      expect(Boat.where(type:'yacht').where(size:'small').ids).to eq([])
    end
  end

  describe "#where" do
    it "should find objects by multiple attributes" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'

      expect(Boat.where(type:'ferry', color:'white').ids).to eq([1])
      expect(Boat.where(type:'ferry', color:'blue').ids).to eq([])
      expect(Boat.where(type:'yacht', color:'white').ids).to eq([2])
      expect(Boat.where(type:'yacht', color:'blue').ids).to eq([3])
    end
  end

  describe "#where" do
    it "should not find anything for attributes without search" do
      expect(Boat.where(size:'big').ids).to eq([])
    end
  end

  describe "#count" do
    it "should return number of results" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'

      expect(Boat.count.result).to eq(3)

      # check compare methods:
      expect(Boat.count == 3).to eq(true)
      expect(Boat.count != 2).to eq(true)
      expect(Boat.count > 2).to eq(true)
      expect(Boat.count < 4).to eq(true)
      expect(Boat.count >= 3).to eq(true)
      expect(Boat.count <= 3).to eq(true)
    end
  end

  describe "#count and #where" do
    it "should be combinable" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'

      expect(Boat.where(type:'yacht').count.to_int).to eq(2)
      expect(Boat.count.where(type:'yacht').to_int).to eq(2)
      expect(Boat.where(color:'white').count.where(type:'yacht').to_int).to eq(1)
    end
  end

  describe "#random and #where" do
    it "should be combinable" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'

      boat = Boat.where(type:'yacht').random.ids
      expect([2,3]).to include(boat)
    end
  end

  describe "#where and #last/#first" do
    it "should be combinable" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'

      boat = Boat.where(type:'ferry').first.result
      expect(boat.id).to eq(1)
      boat = Boat.where(type:'ferry').last.result
      expect(boat.id).to eq(1)

      boat = Boat.where(type:'yacht').first.result
      expect(boat.id).to eq(2)
      boat = Boat.where(type:'yacht').last.result
      expect(boat.id).to eq(3)

      boat = Boat.where(type:'yacht',color:'blue').first.result
      expect(boat.id).to eq(3)
      boat = Boat.where(type:'yacht',color:'blue').last.result
      expect(boat.id).to eq(3)
    end
  end

  describe "#first/last" do
    it "should accept attributes" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'

      boat = Boat.first(type:'ferry').result
      expect(boat.id).to eq(1)
      boat = Boat.last(type:'ferry').result
      expect(boat.id).to eq(1)

      boat = Boat.first(type:'yacht').result
      expect(boat.id).to eq(2)
      boat = Boat.last(type:'yacht').result
      expect(boat.id).to eq(3)

      boat = Boat.first(type:'yacht',color:'blue').result
      expect(boat.id).to eq(3)
      boat = Boat.last(type:'yacht',color:'blue').result
      expect(boat.id).to eq(3)
    end
  end

  describe "#destroy" do
    it "should update search" do
      boat1 = Boat.build id:1, type:'ferry', color:'white'
      boat2 = Boat.build id:2, type:'yacht', color:'white'

      expect(Boat.where(color:'white').ids).to eq([1,2])
      boat1.destroy
      expect(Boat.where(color:'white').ids).to eq([2])
      boat2.destroy
      expect(Boat.where(color:'white').ids).to eq([])
    end
  end

  describe "#update_attributes" do
    it "should update search" do
      boat1 = Boat.build id:1, type:'ferry', color:'white'
      boat2 = Boat.build id:2, type:'yacht', color:'white'

      expect(Boat.where(color:'white').ids).to eq([1,2])
      expect(Boat.where(color:'blue').ids).to eq([])

      boat1.update_attributes color:'blue'

      expect(Boat.where(color:'white').ids).to eq([2])
      expect(Boat.where(color:'blue').ids).to eq([1])      
    end
  end

  describe "#update_attribute" do
    it "should update search" do
      boat1 = Boat.build id:1, type:'ferry', color:'white'
      boat2 = Boat.build id:2, type:'ferry', color:'blue'
      expect(Boat.where(color:'blue').ids).to eq([2])
      boat1.update_attribute :color, 'blue'
      expect(Boat.where(color:'blue').ids).to eq([1,2])
      boat2.update_attribute :color, 'green'
      expect(Boat.where(color:'blue').ids).to eq([1])
      boat1.update_attribute :color, 'green'
      expect(Boat.where(color:'blue').ids).to eq([])
    end
  end

  describe "#attribute=" do
    it "should update search after a save" do
      boat1 = Boat.build id:1, color:'white'
      expect(Boat.where(color:'white').ids).to eq([1])
      expect(Boat.where(color:'black').ids).to eq([])
      boat1.attributes = { color: 'black' }
      expect(Boat.where(color:'white').ids).to eq([1])
      expect(Boat.where(color:'black').ids).to eq([])
      boat1.save
      expect(Boat.where(color:'white').ids).to eq([])
      expect(Boat.where(color:'black').ids).to eq([1])
    end
  end

  describe "#where and #order" do
    it "should be combinable" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'

      ids = Boat.where(type:'yacht').sort(:color).order(:asc).ids
      expect(ids).to eq([3,2])

      ids = Boat.where(type:'yacht').sort(:color).order(:desc).ids
      expect(ids).to eq([2,3])

      ids = Boat.where(type:'ferry').sort(:color).order(:asc).ids
      expect(ids).to eq([1])

      ids = Boat.where(color:'white').sort(:type).order(:asc).ids
      expect(ids).to eq([1,2])

      ids = Boat.where(color:'white').sort(:type).order(:desc).ids
      expect(ids).to eq([2,1])
    end
  end

  describe "#where and #order" do
    it "should be combinable" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', owner:'Anne'
      boat2 = Boat.build id:2, type:'ferry', color: 'white', owner:'Betty'
      boat3 = Boat.build id:3, type:'ferry', color: 'blue', owner:'Tom'
      boat4 = Boat.build id:4, type:'yacht', color: 'white', owner:'Sarah'
      boat4 = Boat.build id:5, type:'yacht', color: 'white', owner:'Clara'
      boat4 = Boat.build id:6, type:'yacht', color: 'blue', owner:'Ben'

      ids = Boat.where(color:'white', type:'yacht').sort(:owner).order(:asc).ids
      expect(ids).to eq([5,4])
    end
  end

  describe "#first" do
    it "should find the first item" do
      record1 = Record.build id:1
      record2 = Record.build id:2
      record3 = Record.build id:3
      item = Record.first.result
      expect(item).to be_a(Record)
      expect(item.id).to eq(record1.id)
    end
  end

  describe "#last" do
    it "should find the last item" do
      record1 = Record.build id:1
      record2 = Record.build id:2
      record3 = Record.build id:3
      item = Record.last.result
      expect(item).to be_a(Record)
      expect(item.id).to eq(record3.id)
    end
  end

  describe "#random" do
    # really testing for randomness is hard
    # we simply check that a valid id is returned
    it "should find a random item" do
      record1 = Record.build id:1
      record2 = Record.build id:2
      record3 = Record.build id:25
      ids = [record1.id, record2.id, record3.id]

      item = Record.random.ids
      expect(ids.include? item).to eq(true)
    end
  end

  describe "queries on relations" do
    before(:each) do
      @boat1 = Boat.build id:1, type: 'yacht', color: 'white'
      @sail1 = Sail.build id:1, type: 'small', color: 'white'
      @sail2 = Sail.build id:2, type: 'big',   color: 'blue'
      @sail3 = Sail.build id:3, type: 'big',   color: 'white'
      @boat1.sails.add @sail1
      @boat1.sails.add @sail2
      @boat1.sails.add @sail3
            
      @boat2 = Boat.build id:2, type: 'ferry', color: 'blue'
      @sail4 = Sail.build id:4, type: 'small', color: 'red'
      @sail5 = Sail.build id:5, type: 'big',   color: 'red'
      @sail6 = Sail.build id:6, type: 'small', color: 'white'
      @boat2.sails.add @sail4
      @boat2.sails.add @sail5
      @boat2.sails.add @sail6
    end

    describe "#count on a relation" do
      it "should return number of relations" do
        expect(@boat1.sails.count.result).to eq(3)
        expect(@boat2.sails.count.result).to eq(3)
      end
    end

    describe "#ids on a relation" do
      it "should return object ids" do
        expect(@boat1.sails.ids.result).to eq([1,2,3])
        expect(@boat2.sails.ids.result).to eq([4,5,6])
      end
    end

    describe "#where and #ids on a relation" do
      it "should return correct ids" do
        expect(@boat1.sails.where(type:'big').ids.result).to eq([2,3])
        expect(@boat2.sails.where(type:'big').ids.result).to eq([5])
      end
    end

    describe "#where on a relation" do
      it "should return correct objects" do
        expect(@boat1.sails.where(type:'big').count).to eq(2)
        expect(@boat2.sails.where(type:'big').count).to eq(1)
      end
    end

    describe "#where and #count on a relation" do
      it "should return correct number" do
        expect([2,3]).to include(@boat1.sails.where(type:'big').random.ids)
        expect([5]).to include(@boat2.sails.where(type:'big').random.ids)
      end
    end

    describe "#first on a relation" do
      it "should return first object" do
        expect(@boat1.sails.first.ids.result).to eq(1)
        expect(@boat2.sails.first.ids.result).to eq(4)
      end
    end

    describe "#last on a relation" do
      it "should return last object" do
        expect(@boat1.sails.last.ids.result).to eq(3)
        expect(@boat2.sails.last.ids.result).to eq(6)
      end
    end
    
    describe "#where and #first/#last on a relation" do
      it "should return first/last object" do
        expect(@boat1.sails.where(color:'white').first.ids).to eq(1)
        expect(@boat1.sails.where(color:'white').last.ids).to eq(3)

        expect(@boat2.sails.where(color:'white').first.ids).to eq(6)
        expect(@boat2.sails.where(color:'white').last.ids).to eq(6)

        expect(@boat1.sails.first(color:'white').ids).to eq(1)
        expect(@boat1.sails.last(color:'white').ids).to eq(3)

        expect(@boat2.sails.first(color:'white').ids).to eq(6)
        expect(@boat2.sails.last(color:'white').ids).to eq(6)
      end
    end

    describe "#sort and #order on a relation" do
      it "should return last object" do
        expect(@boat1.sails.sort(:color).ids.result).to eq([2,1,3])
        expect(@boat1.sails.sort(:type).ids.result).to eq([2,3,1])
        
        expect(@boat1.sails.sort(:color).order(:desc).ids.result).to eq([1,3,2])
        expect(@boat1.sails.sort(:type).order(:desc).ids.result).to eq([1,2,3])
      end
    end
    
    describe "#random on a relation" do
      it "should return random object" do
        expect([1,2,3]).to include(@boat1.sails.random.ids)
      end
    end

  end

end