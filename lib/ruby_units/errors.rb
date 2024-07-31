module RubyUnits
  class IncompatibleUnitsError < StandardError
    def initialize(message = "Incompatible units")
      super(message)
    end
  end
end
