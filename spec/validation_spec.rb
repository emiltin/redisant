require 'spec_helper'

class Food < Record
  attribute :name, required: true, unique: true
  attribute :color, required: true, unique: true
end


RSpec.describe Record do

  describe "#build" do
    it "should return oject with errors if validations fail" do
      food = Food.build color: 'white'
      expect(food).to be_a(Food)
      expect(food.errors).to eq({'name'=>'is required'})
    end
  end
  
  describe "validation of required attributes" do
    it "should have no errors when not saved" do
      food = Food.new
      expect(food.errors).to eq(nil)
    end

    it "should fail if any required attribute is empty" do
      food = Food.new
      expect(food.save).to eq(false)
      expect(food.errors).to eq({'name'=>'is required', 'color'=>'is required'})
      food.name = "cherry"
      expect(food.save).to eq(false)
      expect(food.errors).to eq({'color'=>'is required'})
    end

    it "should succeed if all required attributes are present" do
      food = Food.new
      food.name = "cherry"
      food.color = "purple"
      expect(food.save).to eq(true)
      expect(food.errors).to eq(nil)
    end
  end

  describe "validation of unique attributes" do
    it "should have no errors when not saved" do
      food = Food.new
      expect(food.errors).to eq(nil)
    end

    it "should fail if any attribute is not unique" do
      food1 = Food.build name: 'melon', color: 'yellow'
      food2 = Food.new name: 'melon', color: 'yellow'
      expect(food1.errors).to eq(nil)
      expect(food2.errors).to eq(nil)
      expect(food2.save).to eq(false)
      expect(food2.errors).to eq({'name'=>'must be unique','color'=>'must be unique'})
      food2.name = 'cherry'
      expect(food2.save).to eq(false)
      expect(food2.errors).to eq({'color'=>'must be unique'})
    end

    it "should succeed if all attributes are unique" do
      food1 = Food.build name: 'melon', color: 'yellow'
      food2 = Food.new name: 'apple', color: 'green'
      expect(food2.save).to eq(true)
      expect(food2.errors).to eq(nil)
    end
  end
 
  describe "#save!" do
    it "should raise error if validation failed" do
      food = Food.new
      expect { food.save! }.to raise_exception(Redisant::ValidationFailed)
    end
  end

end