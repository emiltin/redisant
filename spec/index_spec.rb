require 'spec_helper'

class Book < Record
  attribute :name
  attribute :created_at
  index :name, type: :alpha
  index :created_at, type: :time
end


RSpec.describe Record do

  before(:each) do
    @book1 = Book.build id:1, name:'Animals', created_at:Time.new(2015,10,10,19,55,22)
    @book2 = Book.build id:2, name:'Cellos', created_at:Time.new(2015,10,10,19,55,23)
    @book3 = Book.build id:3, name:'Boats', created_at:Time.new(2015,10,10,19,55,21)
  end

  describe "#ids" do
    it "should be able to sort by index alpha asc" do
      ids = Book.ids sort: :name, order: :asc
      expect(ids).to eq([1,3,2])
    end

    it "should be able to sort by index alpha desc" do
      ids = Book.ids sort: :name, order: :desc
      expect(ids).to eq([2,3,1])
    end

    it "should be able to sort by index time asc" do
      ids = Book.ids sort: :created_at, order: :asc
      expect(ids).to eq([3,1,2])
    end

    it "should be able to sort by index time desc" do
      ids = Book.ids sort: :created_at, order: :desc
      expect(ids).to eq([2,1,3])
    end
  end
  
end