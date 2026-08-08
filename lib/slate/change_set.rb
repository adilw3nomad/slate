# frozen_string_literal: true

require "json"

module Slate
  # Value object holding a set of proposed attribute changes to some record.
  # Serialises to JSON for storage; applies over a base record for previews.
  class ChangeSet
    def self.from_json(string)
      new(JSON.parse(string))
    end

    attr_reader :attributes

    def initialize(attributes)
      @attributes = attributes.transform_keys(&:to_s)
      freeze
    end

    def symbolized
      attributes.transform_keys(&:to_sym)
    end

    def to_json(*)
      JSON.generate(attributes)
    end

    # Merge these changes over a base record's attributes, without mutating it.
    def apply_to(base_attributes)
      base_attributes.merge(symbolized)
    end

    def ==(other)
      other.is_a?(ChangeSet) && other.attributes == attributes
    end
    alias eql? ==

    def hash
      attributes.hash
    end
  end
end
