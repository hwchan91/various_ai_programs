require './lisp_methods'
require './equation_parser.rb'

# prerequisite: exp deos not include any addition/substraction
class FactorizeService
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

  def op(exp)
    return false unless exp.class == Array
    exp[1]
  end

  def negative_exp?(exp)
    exp.class == Array && exp.first == '-'
  end
end

module Factorize
  def factorize(exp)
    FactorizeService.new(exp: exp).process
  end

  def unfactorize(factors)
    return 1.0 if factors.empty? #factors is empty only when the input is '1'
    result = nil
    factors.each do |factor|
      result = result ? [factor, '*', result] : [factor]
    end
    result
  end

  # prerequisite: both numer and denom are arrays resulted from factorize
  def divide_factors(numer, denoms)
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
end

# exp = EquationParser.string_to_biexp('3 * x ^ 2 * x ^ 3 * 4 * y ^ 3 * 5 * sin x / 3')
# exp = EquationParser.string_to_biexp('3 * x ^ 2 * x ^ 3 * 4 * y ^ 3 * 5 * sin x * 0')
# exp = EquationParser.string_to_biexp('x ^ 2 * x ^ 3 * y ^ 3 * sin x * 1')
# exp = EquationParser.string_to_biexp('1')
# exp = EquationParser.string_to_biexp('x * sin(x^ 2)')
# p exp

# f = Class.new.extend(Factorize)
# p list = f.factorize(exp)
# p f.unfactorize(list)

# exp1 = EquationParser.string_to_biexp('3 * x ^ 2 * x ^ 3 * 4 * y ^ 3 * 5 * sin x')
# numer = f.factorize(exp1)

# exp2 = EquationParser.string_to_biexp('x ^ 4 * y ^ 3 * 4')
# denom = f.factorize(exp2)

# p f.divide_factors(numer, denom)

