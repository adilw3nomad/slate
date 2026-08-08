# frozen_string_literal: true

require "dry/validation"

module Slate
  module Contracts
    # Validates a proposed set of attribute changes to a menu item.
    class ChangeContract < Dry::Validation::Contract
      params do
        optional(:name).filled(:string)
        optional(:description).maybe(:string)
        optional(:price_cents).filled(:integer, gteq?: 0)
        optional(:available).filled(:bool)
      end

      rule do
        base.failure("provide at least one change") if values.to_h.empty?
      end
    end
  end
end
