require 'pry'
require './equation_parser.rb'
require './rule_based_translator.rb'

class EquationSimplifier < RuleBasedTranslator
  class << self
    attr_accessor :simplify_rules

    def simp(equation_string)
      biexp = string_to_biexp(equation_string)
      simplified = simplify(biexp)
      biexp_to_string(simplified)
    end

    def simplify(exp)
      return exp unless exp.class == Array
      simplify_exp(exp.map { |elem| simplify elem })
    end

    def simplify_exp(exp)
      case
      when simplified_exp = translate(input: exp,
                                      rules: simplify_rules,
                                      patterns_func: Proc.new { |lhs, _, rhs| [lhs] },
                                      response_func: Proc.new { |lhs, _, rhs| rhs },
                                      action_func: Proc.new do |response, variable_map|
                                        variable_map.each { |sym, val| response = sublis(response, sym ,val) }
                                        simplify(response)
                                      end)
        simplified_exp
      when evaluable?(exp)
        eval(biexp_to_string(exp))
      else
        exp
      end
    end

    def evaluable?(exp)
      string = exp.is_a?(String) ? exp : exp.flatten.join(" ")
      !(string =~ /[a-zA-Z=]/)
    end

    def string_to_biexp(string)
      EquationParser.string_to_biexp(string)
    end

    def biexp_to_string(biexp)
      EquationParser.biexp_to_string(biexp)
    end
  end

  @simplify_rules = [
    "x + 0 = x",
    "0 + x = x",
    "x + x = 2 * x",
    "x - 0 = x",
    "0 - x = -x",
    "x - x = 0",
    "- -x = x",
    "x * 1 = x",
    "1 * x = x",
    "x * 0 = 0",
    "0 * x = 0",
    "x * x = x ^ 2",
    "x / 0 = undefined",
    "0 / x = 0",
    "x / 1 = x",
    "x / x = 1",
    "0 ^ 0 = undefined",
    "x ^ 0 = 1",
    "0 ^ x = 0",
    "1 ^ x = 1",
    "x ^ 1 = x",
    "x ^ -1 = 1/x",
    "x * (y/x) = y",
    "(y/x) * x = y",
    "(y * x)/x = y",
    "(x * y)/x = y",
    "x + -x = 0",
    "-x + x = 0",
    "x + y - x = y",
  ].map do |eq|
    biexp = string_to_biexp(eq)
    expand_rules(biexp)
  end
end


# p EquationSimplifier.simp("x + 5 - x")
