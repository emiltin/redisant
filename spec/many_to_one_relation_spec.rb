require 'spec_helper'

# our classes. note that machine and part has a mutual relation
class Machine < Record
  has_many :parts
end

class Part < Record
  belongs_to :machine
end
  
RSpec.describe Machine do
  before(:each) do
    @machine1 = Machine.build id:1
    @part1 = Part.build id:1
  end
  
  describe "#parts" do
    it "should exists" do
      expect(@machine1.respond_to? :parts).to eq(true)
    end
  end

  describe "#parts" do
    it "should be a HasMany relation" do
      expect(@machine1.parts).to be_a(HasMany)
    end
  end
  
  describe "#relations['parts']" do
    it "should be a HasMany relation" do
      expect(@machine1.relations['parts']).to be_a(HasMany)
    end
  end

  describe "#part" do
    it "should not exist" do
      expect(@machine1.respond_to? :part).to eq(false)
    end
  end

  describe "reciprocity" do
    describe "#destroy" do
      it "should nullify reverse relation" do
        @machine1.parts.add @part1
        expect(@part1.machine).to be_a(Machine)
        expect(@part1.machine.id).to eq(1)
        expect(@machine1.parts.ids).to eq([1])
        @machine1.destroy
        expect(@part1.machine.id).to eq(nil)        
      end
    end
  end
  
end

RSpec.describe Part do
  before(:each) do
    @machine1 = Machine.build id:1
    @part1 = Part.build id:1
  end
  
  describe "#machine1" do
    it "should exists" do
      expect(@part1.respond_to? :machine).to eq(true)
    end
  end

  describe "#relations['machine']" do
    it "should be a BelongsTo relation" do
      expect(@part1.relations['machine']).to be_a(BelongsTo)
    end
  end
  
  describe "#machines" do
    it "should not exist" do
      expect(@part1.respond_to? :machines).to eq(false)
    end
  end
  
  describe "reciprocity" do
    describe "#destroy" do
      it "should nullify reverse relation" do
        @machine1.parts.add @part1
        expect(@part1.machine).to be_a(Machine)
        expect(@part1.machine.id).to eq(1)
        expect(@machine1.parts.ids).to eq([1])
        @part1.destroy
        expect(@machine1.parts.ids).to eq([])        
      end
    end
  end
  
end

RSpec.describe HasMany do
  before(:each) do
    @machine1 = Machine.build id:1
    @machine2 = Machine.build id:2
    
    @part1 = Part.build id:1
    @part2 = Part.build id:2
    @part3 = Part.build id:3
    @parts = [@part1,@part2,@part3]
  end

  describe "#count" do
    it "should return zero when empty" do
      expect(@machine1.parts.count).to eq(0)
    end

    it "should return number of items" do
      @parts.each { |part| @machine1.parts.add part }
      expect(@machine1.parts.count).to eq(@parts.size)
    end
  end

  describe "#add" do
    it "should not add nil" do
      @machine1.parts.add nil
      expect(ids @machine1.parts.all).to eq([])      
    end

    it "should raise if adding anything but a Record" do
      expect{ @machine1.parts.add Machine}.to raise_exception(Redisant::InvalidArgument)
    end

    it "should raise if adding wrong Record type" do
      expect{ @machine1.parts.add "bad"}.to raise_exception(Redisant::InvalidArgument)
    end

    it "should add items" do
      @parts.each { |part| @machine1.parts.add part }
      expect(ids @machine1.parts.all).to eq(ids @parts)      
    end

    it "should not add the same items twice" do
      3.times { @machine1.parts.add @parts.first }
      expect(@machine1.parts.count).to eq(1)      
      expect(ids @machine1.parts.all).to eq([@parts.first.id])      
    end

    it "should add array of items" do
      @machine1.parts.add @parts
      expect(ids @machine1.parts.all).to eq(ids @parts)      
    end

  end

  describe "#build" do
    it "should build and add object" do
      part = @machine1.parts.build name:'foot'
      expect(part.attribute :name).to eq('foot')
      expect(@machine1.parts.count).to eq(1)
      expect(ids @machine1.parts.all).to eq([4])
    end
  end

  describe "#<<" do
    it "should add items" do
      @machine1.parts.add @parts
      expect(ids @machine1.parts.all).to eq(ids @parts)      
    end

    it "should not add the same items twice" do
      3.times { @machine1.parts << @parts.first }
      expect(@machine1.parts.count).to eq(1)      
      expect(ids @machine1.parts.all).to eq([@parts.first.id])      
    end

    it "should add array of items" do
      @machine1.parts << @parts
      expect(ids @machine1.parts.all).to eq(ids @parts)      
    end
  end

  describe "#remove" do
    it "should ignore nil" do
      @machine1.parts.add @parts
      @machine1.parts.remove nil
      expect(ids @machine1.parts.all).to eq([1,2,3])      
      expect(Part.count).to eq(3)      
    end

    it "should remove first item" do
      @machine1.parts.add @parts
      @machine1.parts.remove @part1
      expect(ids @machine1.parts.all).to eq([2,3])      
      expect(Part.count).to eq(3)      
    end

    it "should remove last item" do
      @machine1.parts.add @parts
      @machine1.parts.remove @part3
      expect(ids @machine1.parts.all).to eq([1,2])      
      expect(Part.count).to eq(3)      
    end

    it "should remove middle item" do
      @machine1.parts.add @parts
      @machine1.parts.remove @part2
      expect(ids @machine1.parts.all).to eq([1,3])      
      expect(Part.count).to eq(3)      
    end

    it "should remove all items" do
      @machine1.parts.add @parts
      @machine1.parts.remove @part1
      @machine1.parts.remove @part2
      @machine1.parts.remove @part3
      expect(ids @machine1.parts.all).to eq([])      
      expect(Part.count).to eq(3)      
    end

    it "should remove array of items" do
      @machine1.parts.add @parts
      @machine1.parts.remove [@part1,@part3]
      expect(ids @machine1.parts.all).to eq([2])      
      expect(Part.count).to eq(3)      
    end

  end

  describe "#remove_all" do
    it "should ignore nil" do
      @machine1.parts.add @parts
      @machine1.parts.remove nil
      expect(ids @machine1.parts.all).to eq([1,2,3])      
      expect(Part.count).to eq(3)      
    end

    it "should remove all items" do
      @machine1.parts.add @parts
      @machine1.parts.remove_all
      expect(ids @machine1.parts.all).to eq([])      
      expect(Part.count).to eq(3)      
    end
  end
  
  describe "#all" do
    it "should return empty array when empty" do
      expect(@machine1.parts.all).to eq([])
    end
  
    it "should return all items" do
      @machine1.parts.add @parts
      expect(ids @machine1.parts.all).to eq(ids @parts)      
    end
  end

  describe "#ids" do
    it "should return empty array when empty" do
      expect(@machine1.parts.ids).to eq([])
    end
  
    it "should return all items" do
      @machine1.parts.add @parts
      expect(@machine1.parts.ids).to eq(ids @parts)      
    end
  end

  describe "reciprocity" do
    describe "#add" do
      it "should set reverse relation" do
        @machine1.parts.add @part1
        expect(@machine1.parts.ids).to eq([1])
        expect(@part1.machine).to be_a(Machine)
        expect(@part1.machine.id).to eq(1)
      end

      it "should remove from existing owner" do
        @machine1.parts.add @part1
        expect(@machine1.parts.ids).to eq([1])
        expect(@machine2.parts.ids).to eq([])
        expect(@part1.machine).to be_a(Machine)
        expect(@part1.machine.id).to eq(1)

        @machine2.parts.add @part1
        expect(@machine1.parts.ids).to eq([])
        expect(@machine2.parts.ids).to eq([1])
        expect(@part1.machine).to be_a(Machine)
        expect(@part1.machine.id).to eq(2)
      end
    end

    describe "#remove" do
      it "should nullify reverse relation" do
        @machine1.parts.add @part1
        expect(@machine1.parts.ids).to eq([1])
        expect(@part1.machine).to be_a(Machine)
        expect(@part1.machine.id).to eq(1)
        
        @machine1.parts.remove @part1
        expect(@machine1.parts.ids).to eq([])
        expect(@part1.machine).to eq(nil)
      end
    end
  end
  
end

RSpec.describe BelongsTo do
  before(:each) do
    @machine1 = Machine.build id:1
    @machine2 = Machine.build id:2
    @part1 = Part.build id:1
  end

  describe "#machine" do
    it "should be nil when not set" do
      expect(@part1.machine).to eq(nil)
    end
  end

  describe "#machine=" do
    it "should set relation" do
      @part1.machine = @machine1
      expect(@part1.machine).to be_a(Machine)
      expect(@part1.machine.id).to eq(@machine1.id)
      @part1.machine = nil
      expect(@part1.machine).to eq(nil)
    end
  end

  describe "reciprocity" do
    describe "#machine=" do
      it "should set reverse relation" do
        @part1.machine = @machine1
        expect(@part1.machine).to be_a(Machine)
        expect(@part1.machine.id).to eq(1)
        expect(@machine1.parts.ids).to eq([1])
      end

      it "should nullify reverse relation" do
        @part1.machine = @machine1
        expect(@part1.machine).to be_a(Machine)
        expect(@part1.machine.id).to eq(1)
        expect(@machine1.parts.ids).to eq([1])

        @part1.machine = nil
        expect(@part1.machine).to eq(nil)
        expect(@machine1.parts.ids).to eq([])
      end

      it "should remove from existing owner" do
        @part1.machine = @machine1
        expect(@part1.machine).to be_a(Machine)
        expect(@part1.machine.id).to eq(1)
        expect(@machine1.parts.ids).to eq([1])
        expect(@machine2.parts.ids).to eq([])

        @part1.machine = @machine2
        expect(@part1.machine).to be_a(Machine)
        expect(@part1.machine.id).to eq(2)
        expect(@machine1.parts.ids).to eq([])
        expect(@machine2.parts.ids).to eq([1])
      end
    end
    
  end

end