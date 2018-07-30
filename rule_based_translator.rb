require './pattern_matcher.rb'
require './rule_abbreviator.rb'

class RuleBasedTranslator
  extend RuleAbbreviator

  class << self
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
      Proc.new do |response, variable_map|
        variable_map.each { |variable, value| response.gsub!(variable, join_array(value)) }
        response
      end
    end

    def join_array(arr)
      return "" unless arr
      arr.join(" ")
    end
  end
end

