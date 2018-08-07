require './factorize.rb'

module Integration
  include ::Factorize

  def integrate(exp, x)
    case
    when free_of_var?(exp, x) # int c dx = c*x
      return [exp, '*', x]
    when negative_exp?(exp)
      return ['-', integrate(exp.last, x)] # not sure if typo in PAIP
    when ['+', '-'].include?(op(exp)) # int (f + g) = int f + int g ; nt (f - g) = int f - int g
      return [integrate(exp.first, x), op(exp), integrate(exp.last, x)]
    end

    const_factors, x_factors = partition_if(Proc.new { |factor| free_of_var?(factor, x) }, factorize(exp))
    deriv_result = nil

    int_result =  case
                  when x_factors.empty? then x
                  when x_factors.detect { |factor| deriv_result = deriv_divides(factor, x_factors, x) }
                    deriv_result
                  else
                    ['int?', unfactorize(x_factors), x] # when cannot solve
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
    rules = expand_equations([
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
    simplify(['d', y, x])
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
end
