$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'redisant'

port = ENV['REDIS_PORT'] || 6387
puts "Connecting to Redis on port #{port}"
Connection.new ENV['REDIS_HOST'], port

RSpec.configure do |config|
  config.before(:each) do
    $redis.flushall
  end
end

def ids objects
  objects.map { |object| object.id }
end
