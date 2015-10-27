$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'redisant'

RSpec.configure do |config|
  config.before(:each) do
    $redis.flushall
  end
end

def ids objects
  objects.map { |object| object.id }
end
