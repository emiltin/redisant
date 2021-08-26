class Index
  
  attr_reader :name, :class, :options, :type, :order
  def initialize name, klass, options
    @name = name.to_s
    @class = klass
    @options = options
    @type = options[:type].to_s
  end

end
