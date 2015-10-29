require 'spec_helper'

class Book < Record
  attribute :name, index: :alpha
  attribute :created_at, index: :time
end


RSpec.describe Record do

  before(:each) do
    @book1 = Book.build id:1, name:'Animals', created_at:Time.new(2015,10,10,19,55,22)
    @book2 = Book.build id:2, name:'Cellos', created_at:Time.new(2015,10,10,19,55,23)
    @book3 = Book.build id:3, name:'Boats', created_at:Time.new(2015,10,10,19,55,21)
  end

  describe "#ids" do
    it "should sort by id if no index" do
      ids = Book.ids
      expect(ids).to eq([1,2,3])
    end

    it "should be sortable by alphanumeric index ascending" do
      ids = Book.ids sort: :name, order: :asc
      expect(ids).to eq([1,3,2])
    end

    it "should be sortable by alphanumeric index descending" do
      ids = Book.ids sort: :name, order: :desc
      expect(ids).to eq([2,3,1])
    end

    it "should be sortable by time index time ascending" do
      ids = Book.ids sort: :created_at, order: :asc
      expect(ids).to eq([3,1,2])
    end

    it "should be sortable by time index time descending" do
      ids = Book.ids sort: :created_at, order: :desc
      expect(ids).to eq([2,1,3])
    end
  end
  
end