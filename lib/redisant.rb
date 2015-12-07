require "redisant/version"

require 'redis'

require_relative 'redisant/errors.rb'
require_relative 'redisant/inflector'
require_relative 'redisant/attribute_builder'
require_relative 'redisant/relation_builder'
require_relative 'redisant/index_builder'
require_relative 'redisant/search_builder'
require_relative 'redisant/relations'
require_relative 'redisant/index'
require_relative 'redisant/search'
require_relative 'redisant/criteria'
require_relative 'redisant/records'


# connect to redis db
$redis = Redis.new(host: '127.0.0.1', port: 6379)
