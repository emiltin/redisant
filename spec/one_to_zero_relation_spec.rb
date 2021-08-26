require 'spec_helper'

# our classes. note that town does not have a has_many definition
class Town < Record
end

class Street < Record
  belongs_to :town
end


RSpec.describe BelongsTo do
  before(:each) do
    @town = Town.build(id:1)
    @street = Street.build(id:1)
  end
  
  describe "#town" do
    it "should exists" do
      expect(@street.respond_to? :town).to eq(true)
    end
  end

  describe "#town" do
    it "should be nil when not set" do
      expect(@street.town).to eq(nil)
    end
  end

  describe "#relations['town']" do
    it "should be a BelongsTo relation" do
      expect(@street.relations['town']).to be_a(BelongsTo)
    end
  end
  
  describe "#towns" do
    it "should not exist" do
      expect(@street.respond_to? :towns).to eq(false)
    end
  end

  describe "#town=" do
    it "should set relation" do
      @street.town = @town
      expect(@street.town).to be_a(Town)
      expect(@street.town.id).to eq(@town.id)
      @street.town = nil
      expect(@street.town).to eq(nil)
    end
  end
  
end