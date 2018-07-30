require './lisp_methods.rb'

module RuleAbbreviator
  include LispMethods

  $pat_abbrev = {
    "?X*" => %w(?* ?X),
    "?Y*" => %w(?* ?Y),
    "?X+" => %w(?+ ?X),
    "?Y+" => %w(?+ ?Y),
    "x"   => %w(?+ ?X),
    "y"   => %w(?+ ?Y),
  }

  def expand_rules(rules)
    $pat_abbrev.each do |pattern, expansion|
      rules = sublis(rules, pattern, expansion)
    end
    rules
  end

  def add_pat_abbrev(pattern:, expansion:)
    $pat_abbrev ||= {}
    $pat_abbrev[pattern] = expansion
  end
end
