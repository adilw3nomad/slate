# auto_register: false
# frozen_string_literal: true

module Slate
  module Views
    module Helpers
      # Human-friendly name for a changed field in the diff view.
      def field_label(field)
        {"price_cents" => "Price", "available" => "Availability"}
          .fetch(field.to_s, field.to_s.tr("_", " ").capitalize)
      end

      # Human-friendly rendering of a changed field's value for the diff view.
      def format_field(field, value)
        case field.to_s
        when "price_cents" then Slate::Money.new(value).to_s
        when "available" then value ? "Available" : "Unavailable"
        else value.to_s
        end
      end
    end
  end
end
