module Pismo
  module Reader
    
    module_function

    def create(raw_content, options = {})
      type = options.delete(:reader)
      case type
      when :score
        Pismo::Reader::Tree.new(raw_content, options)
      when :cluster
        Pismo::Reader::Cluster.new(raw_content, options)
      else
        Pismo::Reader::Tree.new(raw_content, options)
      end
    end
  end
end
