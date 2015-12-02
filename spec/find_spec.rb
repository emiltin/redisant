require 'spec_helper'

class Boat < Record
  attribute :type, search: true
  attribute :color, search: true
  attribute :size
end


RSpec.describe Record do

  before(:each) do
  end

  describe "#search" do
    it "should find objects by single attribute" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'

      expect(Boat.where(type:'ferry')).to eq([1])
      expect(Boat.where(type:'yacht')).to eq([2,3])
      expect(Boat.where(type:'raft')).to eq([])

      expect(Boat.where(color:'white')).to eq([1,2])
      expect(Boat.where(color:'blue')).to eq([3])
      expect(Boat.where(color:'red')).to eq([])
    end
  end

  describe "#where" do
    it "should find objects by multiple attributes" do
      boat1 = Boat.build id:1, type:'ferry', color:'white', size:'big'
      boat2 = Boat.build id:2, type:'yacht', color: 'white', size:'small'
      boat3 = Boat.build id:3, type:'yacht', color: 'blue', size:'medium'

      expect(Boat.where(type:'ferry', color:'white')).to eq([1])
      expect(Boat.where(type:'ferry', color:'blue')).to eq([])
      expect(Boat.where(type:'yacht', color:'white')).to eq([2])
      expect(Boat.where(type:'yacht', color:'blue')).to eq([3])
    end
  end

  describe "#where" do
    it "should not find anything for attributes without search" do
      expect(Boat.where(size:'big')).to eq([])
    end
  end

  describe "#destroy" do
    it "should update search" do
      boat1 = Boat.build id:1, type:'ferry', color:'white'
      boat2 = Boat.build id:2, type:'yacht', color:'white'

      expect(Boat.where(color:'white')).to eq([1,2])
      boat1.destroy
      expect(Boat.where(color:'white')).to eq([2])
      boat2.destroy
      expect(Boat.where(color:'white')).to eq([])
    end
  end

  describe "#update_attributes" do
    it "should update search" do
      boat1 = Boat.build id:1, type:'ferry', color:'white'
      boat2 = Boat.build id:2, type:'yacht', color:'white'

      expect(Boat.where(color:'white')).to eq([1,2])
      expect(Boat.where(color:'blue')).to eq([])
      
      boat1.update_attributes color:'blue'

      expect(Boat.where(color:'white')).to eq([2])
      expect(Boat.where(color:'blue')).to eq([1])      
    end
  end

  describe "#update_attribute" do
    it "should update search" do
      boat1 = Boat.build id:1, type:'ferry', color:'white'
      boat2 = Boat.build id:2, type:'ferry', color:'blue'
      expect(Boat.where(color:'blue')).to eq([2])
      boat1.update_attribute :color, 'blue'
      expect(Boat.where(color:'blue')).to eq([1,2])
      boat2.update_attribute :color, 'green'
      expect(Boat.where(color:'blue')).to eq([1])
      boat1.update_attribute :color, 'green'
      expect(Boat.where(color:'blue')).to eq([])
    end
  end

  describe "#attribute=" do
    it "should update search after a save" do
      boat1 = Boat.build id:1, color:'white'
      expect(Boat.where(color:'white')).to eq([1])
      expect(Boat.where(color:'black')).to eq([])
      boat1.attributes = { color: 'black' }
      expect(Boat.where(color:'white')).to eq([1])
      expect(Boat.where(color:'black')).to eq([])
      boat1.save
      expect(Boat.where(color:'white')).to eq([])
      expect(Boat.where(color:'black')).to eq([1])
    end
  end

end