class Connection
  def initialize host=nil, port=nil
		$redis = Redis.new( host: host || '127.0.0.1', port: port || 6379 )
	end
end
