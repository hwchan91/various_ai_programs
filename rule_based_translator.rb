require './pattern_matcher.rb'
require './rule_abbreviator.rb'

class RuleBasedTranslator
  extend RuleAbbreviator

  $pat_abbrev = {
    "?X*" => %w(?* ?X),
    "?Y*" => %w(?* ?Y),
    "?X+" => %w(?+ ?X),
    "?Y+" => %w(?+ ?Y),
  }

  class << self
    def translate(input:,
                  rules:,
                  matcher_func: Proc.new { |pattern, input| PatternMatcher.new(pattern: pattern, string: input).solve },
                  patterns_func: Proc.new { |rule| rule[:pattern] },
                  response_func: Proc.new { |rule| rule[:responses].dup },
                  action_func: Proc.new do |response, variable_map|
                    variable_map.each { |variable, value| response.gsub!(variable, join_array(value)) }
                    response
                  end)

      variable_map = nil
      rule = rules.find do |rule|
        patterns_func.call(rule).find do |pattern|
          variable_map = matcher_func.call(pattern, input)
        end
      end
      return unless rule

      action_func.call(response_func.call(rule), variable_map)
    end

    def join_array(arr)
      return "" unless arr
      arr.join(" ")
    end
  end
end

