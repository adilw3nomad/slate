# frozen_string_literal: true

require "time"

module Slate
  module Actions
    module Changes
      class Create < Slate::Action
        include Deps["repos.menu_item_repo", "changes.stage"]

        def handle(request, response)
          item = menu_item_repo.find(request.params[:id])
          changes = diff(item, submitted(request.params))
          apply_at = parse_time(request.params[:apply_at])

          result = stage.call(target: item, changes: changes, apply_at: apply_at)

          if result.success?
            response.redirect_to "/changes"
          else
            response.redirect_to "/items/#{item.id}/edit?error=1"
          end
        end

        private

        # Only the fields actually submitted, coerced to their stored types.
        def submitted(params)
          out = {}
          out[:name] = params[:name] unless blank?(params[:name])
          out[:description] = params[:description] unless params[:description].nil?
          out[:price_cents] = to_cents(params[:price]) unless blank?(params[:price])
          out[:available] = (params[:available] == "1") unless params[:available].nil?
          out
        end

        # Keep only the fields that differ from the item's current values.
        def diff(item, submitted)
          submitted.each_with_object({}) do |(key, value), acc|
            acc[key] = value unless item.public_send(key) == value
          end
        end

        def to_cents(pounds)
          (Float(pounds) * 100).round
        rescue ArgumentError
          nil
        end

        def parse_time(string)
          return nil if blank?(string)

          Time.parse(string)
        rescue ArgumentError
          nil
        end

        def blank?(value)
          value.nil? || value.to_s.strip.empty?
        end
      end
    end
  end
end
