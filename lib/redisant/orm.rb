require 'redis'

require_relative 'errors'
require_relative 'inflector'
require_relative 'attribute_builder'
require_relative 'relation_builder'
require_relative 'index_builder'
require_relative 'relations'
require_relative 'index'
require_relative 'records'



# connect to redis db
$redis = Redis.new(host: '127.0.0.1', port: 6379)
