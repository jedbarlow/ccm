# Usage:
#
# module Commands
#   attr_accessor :some_arg
#
#   class SomeAction < Command
#     def initialize(some_arg:)
#       @some_arg = some_arg
#     end
#
#     def call
#       # do something
#     end
#   end
# end
#
module Commands
  class Command
    def self.call(*args, **kwargs, &block)
      new(*args, **kwargs, &block).call
    end

    def call
      raise NotImplementedError
    end
  end
end
