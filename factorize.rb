require './simple_equation_solver.rb'

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
    when exp.is_a?(Array) && op(exp) == '*'
      fac(exp.first, n)
      fac(exp.last, n)
    when exp.is_a?(Array) && op(exp) == '/'
      fac(exp.first, n)
      fac(exp.last, -n)
    when exp.is_a?(Array) && exp.first == '-'
      @constant = -@constant
      fac(exp.last, n)
    when exp.is_a?(Array) && op(exp) == '**' && exp.last.is_a?(Numeric)
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

  def op(exp)
    exp[1]
  end
end

# exp = EquationParser.string_to_biexp('3 * x ^ 2 * x ^ 3 * 4 * y ^ 3 * 5 * sin x')
# exp = EquationParser.string_to_biexp('3 * x ^ 2 * x ^ 3 * 4 * y ^ 3 * 5 * sin x * 0')
# exp = EquationParser.string_to_biexp('x ^ 2 * x ^ 3 * y ^ 3 * sin x * 1')
# exp = EquationParser.string_to_biexp('1')
# p exp
# p list = Factorize.new(exp: exp).process
# p Factorize.unfactorize(list)
