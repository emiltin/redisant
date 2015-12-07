require 'spec_helper'

class Boat < Record
  attribute :type, index: :string, search: true
  attribute :color, index: :string, search: true
  attribute :owner, index: :string, search: true
  attribute :size
end


RSpec.describe Record do

  before(:each) do
  end

  describe "#where" do
    it "should find objects by single attribute" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'
      
      expect(Boat.where(type:'ferry').to_ary).to eq([1])
      expect(Boat.where(type:'yacht').to_ary).to eq([2,3])
      expect(Boat.where(type:'raft').to_ary).to eq([])

      expect(Boat.where(color:'white').to_ary).to eq([1,2])
      expect(Boat.where(color:'blue').to_ary).to eq([3])
      expect(Boat.where(color:'red').to_ary).to eq([])
    end
  end

  describe "#where" do
    it "should return on array-like object" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'
      
      got = []
      Boat.where(type:'yacht').each { |boat| got << boat }
      expect(got).to eq([2,3])

      got = Boat.where(color:'white').map { |boat| boat }
      expect(got).to eq([1,2])

      got = Boat.where(type:'yacht')
      expect(got.size).to eq(2)
    end
  end

  describe "#where" do
    it "should be chainable" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'
            
      expect(Boat.where(type:'ferry').where(color:'white').to_ary).to eq([1])
      expect(Boat.where(type:'ferry').where(color:'blue').to_ary).to eq([])
      expect(Boat.where(type:'yacht').where(size:'small').to_ary).to eq([])
    end
  end

  describe "#where" do
    it "should find objects by multiple attributes" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'

      expect(Boat.where(type:'ferry', color:'white').to_ary).to eq([1])
      expect(Boat.where(type:'ferry', color:'blue').to_ary).to eq([])
      expect(Boat.where(type:'yacht', color:'white').to_ary).to eq([2])
      expect(Boat.where(type:'yacht', color:'blue').to_ary).to eq([3])
    end
  end

  describe "#where" do
    it "should not find anything for attributes without search" do
      expect(Boat.where(size:'big').to_ary).to eq([])
    end
  end

  describe "#count" do
    it "should return number of results" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'
      
      expect(Boat.count.to_int).to eq(3)
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
      
      boat = Boat.where(type:'yacht').random
      expect([2,3]).to include(boat.id)
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

      expect(Boat.where(color:'white').to_ary).to eq([1,2])
      boat1.destroy
      expect(Boat.where(color:'white').to_ary).to eq([2])
      boat2.destroy
      expect(Boat.where(color:'white').to_ary).to eq([])
    end
  end

  describe "#update_attributes" do
    it "should update search" do
      boat1 = Boat.build id:1, type:'ferry', color:'white'
      boat2 = Boat.build id:2, type:'yacht', color:'white'

      expect(Boat.where(color:'white').to_ary).to eq([1,2])
      expect(Boat.where(color:'blue').to_ary).to eq([])
      
      boat1.update_attributes color:'blue'

      expect(Boat.where(color:'white').to_ary).to eq([2])
      expect(Boat.where(color:'blue').to_ary).to eq([1])      
    end
  end

  describe "#update_attribute" do
    it "should update search" do
      boat1 = Boat.build id:1, type:'ferry', color:'white'
      boat2 = Boat.build id:2, type:'ferry', color:'blue'
      expect(Boat.where(color:'blue').to_ary).to eq([2])
      boat1.update_attribute :color, 'blue'
      expect(Boat.where(color:'blue').to_ary).to eq([1,2])
      boat2.update_attribute :color, 'green'
      expect(Boat.where(color:'blue').to_ary).to eq([1])
      boat1.update_attribute :color, 'green'
      expect(Boat.where(color:'blue').to_ary).to eq([])
    end
  end

  describe "#attribute=" do
    it "should update search after a save" do
      boat1 = Boat.build id:1, color:'white'
      expect(Boat.where(color:'white').to_ary).to eq([1])
      expect(Boat.where(color:'black').to_ary).to eq([])
      boat1.attributes = { color: 'black' }
      expect(Boat.where(color:'white').to_ary).to eq([1])
      expect(Boat.where(color:'black').to_ary).to eq([])
      boat1.save
      expect(Boat.where(color:'white').to_ary).to eq([])
      expect(Boat.where(color:'black').to_ary).to eq([1])
    end
  end

  describe "#where and #order" do
    it "should be combinable" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'
      
      ids = Boat.where(type:'yacht').order(sort: :color, order: :desc)
      expect(ids.to_ary).to eq([2,3])

      ids = Boat.where(type:'yacht').order(sort: :color, order: :asc)
      expect(ids.to_ary).to eq([3,2])

      ids = Boat.where(type:'ferry').order(sort: :color, order: :asc)
      expect(ids.to_ary).to eq([1])

      ids = Boat.where(color:'white').order(sort: :type, order: :asc)
      expect(ids.to_ary).to eq([1,2])

      ids = Boat.where(color:'white').order(sort: :type, order: :desc)
      expect(ids.to_ary).to eq([2,1])
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
      
      ids = Boat.where(color:'white', type:'yacht').order(sort: :owner, order: :asc)
      expect(ids.to_ary).to eq([5,4])
    end
  end

end