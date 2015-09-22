require 'spec_helper'

# our classes. note that room does not have a belongs_to definition
class House < Record
  has_many :rooms
end

class Room < Record
end
  
RSpec.describe HasMany do
  before(:each) do
    @house = House.build
    @room1 = Room.build(id:1)
    @room2 = Room.build(id:2)
    @room3 = Room.build(id:3)
    @rooms = [@room1,@room2,@room3]
  end
  
  describe "#rooms" do
    it "should exists" do
      expect(@house.respond_to? :rooms).to eq(true)
    end
  end

  describe "#rooms" do
    it "should should be a HasMany relation" do
      expect(@house.rooms).to be_a(HasMany)
    end
  end
  
  describe "#relations['rooms']" do
    it "should be a HasMany relation" do
      expect(@house.relations['rooms']).to be_a(HasMany)
    end
  end

  describe "#room" do
    it "should not exist" do
      expect(@house.respond_to? :room).to eq(false)
    end
  end

  describe "#count" do
    it "should return zero when empty" do
      expect(@house.rooms.count).to eq(0)
    end

    it "should return number of items" do
      @rooms.each { |room| @house.rooms.add room }
      expect(@house.rooms.count).to eq(@rooms.size)
    end
  end

  describe "#add" do
    it "should not add nil" do
      @house.rooms.add nil
      expect(ids @house.rooms.all).to eq([])      
    end

    it "should raise if adding anything but a Record" do
      expect{ @house.rooms.add House}.to raise_exception(InvalidArgument)
    end

    it "should raise if adding wrong Record type" do
      expect{ @house.rooms.add "bad"}.to raise_exception(InvalidArgument)
    end

    it "should add items" do
      @rooms.each { |room| @house.rooms.add room }
      expect(ids @house.rooms.all).to eq(ids @rooms)      
    end

    it "should not add the same items twice" do
      3.times { @house.rooms.add @rooms.first }
      expect(@house.rooms.count).to eq(1)      
      expect(ids @house.rooms.all).to eq([@rooms.first.id])      
    end

    it "should add array of items" do
      @house.rooms.add @rooms
      expect(ids @house.rooms.all).to eq(ids @rooms)      
    end
  end

  describe "#build" do
    it "should build and add object" do
      room = @house.rooms.build name:'suite'
      expect(room.attribute :name).to eq('suite')
      expect(@house.rooms.count).to eq(1)
      expect(ids @house.rooms.all).to eq([4])
    end
  end

  describe "#<<" do
    it "should add items" do
      @house.rooms.add @rooms
      expect(ids @house.rooms.all).to eq(ids @rooms)      
    end

    it "should not add the same items twice" do
      3.times { @house.rooms << @rooms.first }
      expect(@house.rooms.count).to eq(1)      
      expect(ids @house.rooms.all).to eq([@rooms.first.id])      
    end

    it "should add array of items" do
      @house.rooms << @rooms
      expect(ids @house.rooms.all).to eq(ids @rooms)      
    end
  end

  describe "#remove" do
    it "should ignore nil" do
      @house.rooms.add @rooms
      @house.rooms.remove nil
      expect(ids @house.rooms.all).to eq([1,2,3])      
      expect(Room.count).to eq(3)      
    end

    it "should remove first item" do
      @house.rooms.add @rooms
      @house.rooms.remove @room1
      expect(ids @house.rooms.all).to eq([2,3])      
      expect(Room.count).to eq(3)      
    end

    it "should remove last item" do
      @house.rooms.add @rooms
      @house.rooms.remove @room3
      expect(ids @house.rooms.all).to eq([1,2])      
      expect(Room.count).to eq(3)      
    end

    it "should remove middle item" do
      @house.rooms.add @rooms
      @house.rooms.remove @room2
      expect(ids @house.rooms.all).to eq([1,3])      
      expect(Room.count).to eq(3)      
    end

    it "should remove all items" do
      @house.rooms.add @rooms
      @house.rooms.remove @room1
      @house.rooms.remove @room2
      @house.rooms.remove @room3
      expect(ids @house.rooms.all).to eq([])      
      expect(Room.count).to eq(3)      
    end

    it "should remove array of items" do
      @house.rooms.add @rooms
      @house.rooms.remove [@room1,@room3]
      expect(ids @house.rooms.all).to eq([2])      
      expect(Room.count).to eq(3)      
    end

  end

  describe "#remove_all" do
    it "should ignore nil" do
      @house.rooms.add @rooms
      @house.rooms.remove nil
      expect(ids @house.rooms.all).to eq([1,2,3])      
      expect(Room.count).to eq(3)      
    end

    it "should remove all items" do
      @house.rooms.add @rooms
      @house.rooms.remove_all
      expect(ids @house.rooms.all).to eq([])      
      expect(Room.count).to eq(3)      
    end
  end
  
  describe "#all" do
    it "should return empty array when empty" do
      expect(@house.rooms.all).to eq([])
    end
  
    it "should return all items" do
      @house.rooms.add @rooms
      expect(ids @house.rooms.all).to eq(ids @rooms)      
    end
  end

  describe "#ids" do
    it "should return empty array when empty" do
      expect(@house.rooms.ids).to eq([])
    end
  
    it "should return all items" do
      @house.rooms.add @rooms
      expect(@house.rooms.ids).to eq(ids @rooms)      
    end
  end

  
end