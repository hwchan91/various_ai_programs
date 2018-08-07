require './lisp_methods'
require './equation_simplifier.rb'

# prerequisite: exp deos not include any addition/substraction
class Factorize
  def initialize(opt = {})
    @factors  = []
    @constant = 1.0
    @exp      = opt[:exp]
  end

  def process
    fac(@exp)
    list_of_factors = case @constant
                      when 0 then [[0.0, '**', 1.0]]
                      when 1 then @factors
                      else [[@constant, '**', 1.0]] + @factors
                      end

    # unfactorize(list_of_factors)
  end

  def fac(exp, n = 1)
    case
    when exp.is_a?(Numeric)
      @constant *= exp ** n
    when op(exp) == '*'
      fac(exp.first, n)
      fac(exp.last, n)
    when op(exp) == '/'
      fac(exp.first, n)
      fac(exp.last, -n)
    when negative_exp?(exp)
      @constant = -@constant
      fac(exp.last, n)
    when op(exp) == '**' && exp.last.is_a?(Numeric)
      fac(exp.first, exp.last * n)
    else
      factor = @factors.detect { |f|  f.first == exp }
      if factor
        factor.push(factor.pop + n)
      else
        @factors << [exp, '**', n]
      end
    end
  end

  def self.unfactorize(factors)
    return 1.0 if factors.empty? #factors is empty only when the input is '1'
    result = nil
    factors.each do |factor|
      result = result ? [factor, '*', result] : [factor]
    end
    result
  end

  # prerequisite: both numer and denom are arrays resulted from factorize
  def self.divide_factors(numer, denoms)
    result = Marshal.load(Marshal.dump(numer)) #deep clone
    denoms.each do |denom|
      factor = result.detect { |factor| factor.first == denom.first }
      if factor
        factor.push(factor.pop - denom.last)
      else
        result << [denom.first, '**', -denom.last]
      end
    end
    result.map! { |factor| factor.last == 0 ? nil : factor }
    result.compact
  end

  def op(exp)
    return false unless exp.class == Array
    exp[1]
  end

  def negative_exp?(exp)
    exp.class == Array && exp.first == '-'
  end
end

# exp = EquationParser.string_to_biexp('3 * x ^ 2 * x ^ 3 * 4 * y ^ 3 * 5 * sin x / 3')
# exp = EquationParser.string_to_biexp('3 * x ^ 2 * x ^ 3 * 4 * y ^ 3 * 5 * sin x * 0')
# exp = EquationParser.string_to_biexp('x ^ 2 * x ^ 3 * y ^ 3 * sin x * 1')
# exp = EquationParser.string_to_biexp('1')
# exp = EquationParser.string_to_biexp('x * sin(x^ 2)')
# p exp
# p list = Factorize.new(exp: exp).process
# p Factorize.unfactorize(list)

# exp1 = EquationParser.string_to_biexp('3 * x ^ 2 * x ^ 3 * 4 * y ^ 3 * 5 * sin x')
# numer = Factorize.new(exp: exp1).process

# exp2 = EquationParser.string_to_biexp('x ^ 4 * y ^ 3 * 4')
# denom = Factorize.new(exp: exp2).process

# p Factorize.divide_factors(numer, denom)


class Integrate
  extend ::LispMethods

  class << self
    def integrate(exp, x)
      case
      when free_of_var?(exp, x) # int c dx = c*x
        return [exp, '*', x]
      when negative_exp?(exp)
        return ['-', integrate(exp.last)] # not sure if typo in PAIP
      when ['+', '-'].include?(op(exp)) # int (f + g) = int f + int g ; nt (f - g) = int f - int g
        return [integrate(exp.first), op(exp), integrate(exp.last)]
      end

      const_factors, x_factors = partition_if(Proc.new { |factor| free_of_var?(factor, x) }, factorize(exp))
      deriv_result = nil

      int_result =  case
                    when x_factors.empty? then x
                    when x_factors.detect { |factor| deriv_result = deriv_divides(factor, x_factors, x) }
                      deriv_result
                    else
                      ['int?', Factorize.unfactorize(x_factors), x] # when cannot solve
                    end

      simplify([unfactorize(const_factors), '*', int_result])
    end


    def negative_exp?(exp)
      exp.class == Array && exp.first == '-'
    end

    def op(exp)
      return false unless exp.class == Array
      exp[1]
    end

    def partition_if(proc, list)
      match_list = []
      list.each do |elem|
        match_list << elem if proc.call(elem)
      end
      unmatch_list = list - match_list
      [match_list, unmatch_list]
    end

    def deriv_divides(factor, factors, x)
      raise 'factor not **' unless op(factor) == '**'
      u, n = factor.first, factor.last
      k = divide_factors(factors, factorize([factor,  '*', deriv(u, x)]))

      case
      when free_of_var?(k, x) # factors = k * u^n * du/dx; Int factors dx = k * Int u^n du
        if n == -1
          [unfactorize(k), '*', ['log', u]]
        else
          [[unfactorize(k), '*', [u, '**', n + 1]], '/', (n + 1)]
        end
      when n == 1 && in_integral_table?(u)
        k2 = divide_factors(factors, factorize([u, '*', deriv(u.last, x)]))
        if free_of_var?(k2, x)
          [integrate_from_table(u.first, u.last), '*', unfactorize(k2)]
        end
      end
    end

    def in_integral_table?(exp)
      return unless exp.class == Array
      integration_table[exp.first]
    end

    def integration_table
      return @integration_table if @integration_table
      rules = EquationSimplifier.expand_equations([
        "Int log(x) dx  = x * log(x) - x",
        "Int exp(x) dx  = exp(x)",
        "Int sin(x) dx  = -cos(x)",
        "Int cos(x) dx  = sin(x)",
        "Int tan(x) dx  = -log(cos(x))",
        "Int sinh(x) dx = cosh(x)",
        "Int cosh(x) dx = sinh(x)",
        "Int tanh(x) dx = log(cosh(x))",
      ])

      @integration_table = {}
      rules.each do |rule|
        @integration_table[rule[0][1][0]] = rule
      end
      @integration_table
    end

    def integrate_from_table(op, arg)
      rule = integration_table[op]
      replace_sym(rule.last, '?X', arg)
    end

    def deriv(y, x)
      EquationSimplifier.simplify(['d', y, x])
    end

    def factorize(exp)
      Factorize.new(exp: exp).process
    end

    def divide_factors(numer, denom)
      Factorize.divide_factors(numer, denom)
    end

    def unfactorize(factors)
      Factorize.unfactorize(factors)
    end

    def free_of_var?(exp, x)
      !find_anywhere(x, exp)
    end

    def find_anywhere(item, tree)
      case
      when item == tree                            then tree
      when tree.class != Array || tree.empty?      then nil
      else
        found = tree.detect { |elem| find_anywhere(item, elem) }
        found ? item : nil
      end
    end

    def simplify(exp)
      EquationSimplifier.simplify(exp)
    end
  end
end

# # p Integrate.find_anywhere([2,3], [1,[1,2,3,[2,3]]])
# # p Integrate.free_of_var?([1,2,3], [3])

# exp1 = EquationParser.string_to_biexp('3 * x ^ 2 * x ^ 3 * 4 * y ^ 3 * 5')
# exp1 = EquationParser.string_to_biexp('3 * x ^ 2 / x ^ 3 * 4 * y ^ 3 * 5')
# exp1 = EquationParser.string_to_biexp('sin(x) * 5')
exp1 = EquationParser.string_to_biexp('x * sin(x^ 2)')

p result = Integrate.integrate(exp1, 'x')
p EquationParser.biexp_to_string(result)
