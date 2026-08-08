# frozen_string_literal: true

module Slate
  # Value object for a price held as integer pence. Immutable, equal by value.
  class Money
    attr_reader :cents

    def initialize(cents)
      @cents = Integer(cents)
      freeze
    end

    def to_s
      format("£%.2f", cents / 100.0)
    end

    def ==(other)
      other.is_a?(Money) && other.cents == cents
    end
    alias eql? ==

    def hash
      cents.hash
    end
  end
end
