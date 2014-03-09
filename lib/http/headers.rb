require 'http/headers/mixin'

module HTTP
  class Headers
    # Matches HTTP header names when in "Canonical-Http-Format"
    CANONICAL_HEADER = /^[A-Z][a-z]*(-[A-Z][a-z]*)*$/

    def initialize
      @pile = []
    end

    def set(name, value)
      delete(name)
      add(name, value)
    end

    alias_method :[]=, :set

    def delete(name)
      name = canonicalize_header name.to_s
      @pile.delete_if { |k, _| k == name }
    end

    def add(name, value)
      name = canonicalize_header name.to_s
      Array(value).each { |v| @pile << [name, v] }
    end

    def get(name)
      name = canonicalize_header name.to_s
      @pile.select { |k, _| k == name }
    end

    def [](name)
      values = get(name).map { |_, v| v }

      case values.count
      when 0 then nil
      when 1 then values.first
      else        values
      end
    end

    def to_h
      Hash[keys.map { |k| [k, self[k]] }]
    end

    def keys
      @pile.map { |k, _| k }.uniq
    end

    def each(&block)
      @pile.each(&block)
    end

    def initialize_copy(orig)
      super
      @pile = @pile.map { |pair| pair.dup }
    end

    def merge(other)
      dup.tap do |copy|
        self.class.from_hash(other).to_h.each do |name, values|
          copy.set name, values
        end
      end
    end

    def self.from_hash(hash)
      hash = case
             when hash.respond_to?(:to_hash) then hash.to_hash
             when hash.respond_to?(:to_h)    then hash.to_h
             else fail Error, '#to_hash or #to_h object expected'
             end

      headers = new
      hash.each { |k, v| headers.add k, v }
      headers
    end

  private

    # Transform to canonical HTTP header capitalization
    # @param [String] name
    # @return [String]
    def canonicalize_header(name)
      name[CANONICAL_HEADER] || name.split(/[\-_]/).map(&:capitalize).join('-')
    end
  end
end
