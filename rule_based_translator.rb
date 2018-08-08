require './pattern_matcher.rb'
require './lisp_methods.rb'

module RuleBasedTranslator
  include LispMethods

  PAT_ABBREV = {
    "?X*" => %w(?* ?X),
    "?Y*" => %w(?* ?Y),
    "?X+" => %w(?+ ?X),
    "?Y+" => %w(?+ ?Y),
    "x"   => "?X",
    "y"   => "?Y",
    "z"   => "?Z",
    "u"   => "?U",
    "v"   => "?V",
    "n"   => %w(?= ?N ?N.is_a?(Numeric)),
    "m"   => %w(?= ?M ?M.is_a?(Numeric)),
    "s"   => %w(?= ?S !(?S.is_a?(Numeric))),
  }.freeze

  # class << self
    def translate(input:,
                  rules:,
                  matcher_func: self.matcher_func,
                  patterns_func: Proc.new { |rule| rule[:pattern] },
                  response_func: Proc.new { |rule| rule[:responses].dup },
                  action_func: self.action_func)

      variable_map = nil
      rule = rules.find do |rule|
        patterns_func.call(rule).find do |pattern|
          variable_map = matcher_func.call(pattern, input)
        end
      end
      return unless rule

      action_func.call(response_func.call(rule), variable_map)
    end

    def matcher_func
      Proc.new { |pattern, input| PatternMatcher.new(pattern: pattern, string: input).solve }
    end

    def action_func
      Proc.new { |response, variable_map| sublis(response, variable_map) }
    end

    def join_array(arr)
      return "" unless arr
      arr.join(" ")
    end

    def expand_rules(rules)
      sublis(rules, PAT_ABBREV)
    end

    def expand_pattern(rules)
      rules.each do |rule|
        rule[:pattern] = expand_rules(rule[:pattern])
      end
      rules
    end
  # end
end

