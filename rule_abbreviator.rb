# require './lisp_methods.rb'

# module RuleAbbreviator
#   include LispMethods

#   PAT_ABBREV = {
#     "?X*" => %w(?* ?X),
#     "?Y*" => %w(?* ?Y),
#     "?X+" => %w(?+ ?X),
#     "?Y+" => %w(?+ ?Y),
#     "x"   => "?X",
#     "y"   => "?Y",
#   }.freeze

#   def expand_rules(rules)
#     PAT_ABBREV.each do |pattern, expansion|
#       rules = sublis(rules, pattern, expansion)
#     end
#     rules
#   end
# end
