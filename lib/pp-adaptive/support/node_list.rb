require "virtus"

module AdaptivePayments
  class NodeList < Virtus::Attribute::Object
    primitive ::Array

    attr_reader :type

    class << self
      def [](type)
        raise ArgumentError, "Lists may only be created from JsonModel classes" unless type <= JsonModel

        Class.new(self) do
          default lambda { |m, a| CoercedArray.new(type) }

          define_method :type do
            type
          end

          define_method :coerce do |value|
            CoercedArray.new(type) + Array(value)
          end
        end
      end
    end
  end
end