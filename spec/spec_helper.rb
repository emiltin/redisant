$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'redisant'


CYCLE = 8


RSpec.configure do |config|
  config.before(:each) do
    $redis.flushall
    History.reset
  end
end


def ids objects
  objects.map { |object| object.id }
end



class History
  def self.reset
    @@count = nil
  end
  
  def self.count
    @@count ||= 0
  end

  def self.bump
    @@count ||= 0
    @@count = (@@count+1) #% 3
  end
end
