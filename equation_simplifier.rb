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
    # "x ^ -1 = 1/x", #cannot parse -1 correctly
    "x * (y/x) = y",
    "(y/x) * x = y",
    "(y * x)/x = y",
    "(x * y)/x = y",
    "x + -x = 0",
    "-x + x = 0",
    "x + y - x = y",
    "log(1) = 0",
    "log(0) = undefined",
    "log(e) = 1",
    "sin(0) = 0",
    "sin(pi) = -1",
    "cos(0) = 1",
    "cos(pi) = -1",
    "sin(pi/2) = 1",
    "cos(pi/2) = 0",
    "log(e^x) = x",
    "e^(log(x)) = x",
    "(x^y) * (x^z) = x^(y+z)",
    "(x^y) / (x^z) = x^(y-z)",
    "log(x) + log(y) = log(x*y)",
    "log(x) - log(y) = log(x/y)",
    "(sin(x))^2 + (cos(x))^2 = 1",
  ].map { |eq| expand_rules(string_to_biexp(eq)) } +
  [ [["?X", "**", -1.0], "=", [1.0, "/", "?X"]] ] +
  [
    "s * n = n * s",
    "n * (m * x) = (n * m) * x",
    "x * (n * y) = n * (x * y)",
    "(n * x) * y = n * (x * y)",
    "n + s = s + n",
    "(x + m) + n = x + (n + m)",
    "x + (y + n) = (x + y) + n",
    "(x + n) + y = (x + y) + n",
    "dx/dx = 1",
    "d(u+v)/dx = (du/dx)+(dv/dx)",
    "d(u-v)/dx = (du/dx)+(dv/dx)",
    "d(-u)/dx = -(du/dx)",
    "d(u*v)/dx = u*(dv/dx) + v*(du/dx)",
    "d(u/v)/dx = (v*(du/dx) - u*(dv/dx))/(v^2)",
    "d(u^n)/dx = n*u^(n-1) * (du/dx)",
    "d(u^v)/dx = v*u^(v-1) * (du/dx) + u^v*(log u)*(dv/dx)",
    "d(log u)/dx = (du/dx)/u",
    "d(sin u)/dx = (cos u) * (du/dx)",
    "d(cos u)/dx = -(sin u) * (du/dx)",
    "d(e^u)/dx = (e^u) * (du/dx)",
    "du/dx = 0"
  ].map do |eq|
    biexp = string_to_biexp(eq)
    biexp[0] = expand_rules(biexp[0])
    %w(x y n m s u v).each { |v| biexp[2] = sublis(biexp[2], v, "?#{v.upcase}") }
    biexp
  end
end


# p EquationSimplifier.simp("2 * x * 3 * y* 4 * z * 5 * 6")

# p EquationSimplifier.simp("3 * x * 4 *  (1/ x) * 5 * 6 * x * 2")

# p EquationSimplifier.simp("3 + x + 4 - x")

# p EquationSimplifier.simp( "x ^ 2 * x ^ 3" )

# p EquationSimplifier.simp("d((a*x^2 + b*x + c)/x)/dx")

# p EquationSimplifier.simp("sin(2*x)^2 + cos(d(x^2)/dx)^2")

# p EquationSimplifier.simp("sin(2*x) * sin(d(x^2)/dx) + cos(2*x) * cos(x * d(y*2)/dy)")
