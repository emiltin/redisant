$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'redisant'

Connection.new ENV['REDIS_HOST'], ENV['REDIS_PORT']

RSpec.configure do |config|
  config.before(:each) do
    $redis.flushall
  end
end

def ids objects
  objects.map { |object| object.id }
end
