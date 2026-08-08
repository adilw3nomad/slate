# frozen_string_literal: true

module Slate
  module Repos
    class MenuItemRepo < Slate::DB::Repo
      def create(attrs)
        now = Time.now
        menu_items.changeset(:create, {created_at: now, updated_at: now}.merge(attrs)).commit
      end

      def find(id)
        menu_items.by_pk(id).one
      end

      def update(id, attrs)
        menu_items.by_pk(id).changeset(:update, attrs.merge(updated_at: Time.now)).commit
      end

      def all
        menu_items.to_a
      end
    end
  end
end
