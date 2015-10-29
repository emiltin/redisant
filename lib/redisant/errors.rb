module Redisant
  class Error < StandardError
    attr_reader :message
    def initialize message
      @message = message
    end
  end

  class InvalidArgument < Error
    def initialize message
      super message
    end
  end
end
