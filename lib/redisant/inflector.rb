class Inflector
  def self.pluralize name
    "#{name}s"
  end

  def self.singularize name
    name.to_s.chomp("s")
  end

  def self.constantize name
    Object.const_get name.to_s.capitalize
  end
end
