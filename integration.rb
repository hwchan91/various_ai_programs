require './factorize.rb'

module Integration
  include Factorize

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
        [unfactorize(k), '*', ['ln', u]]
      else
        [[unfactorize(k), '*', [u, '**', n + 1]], '/', (n + 1)]
      end
    when n == 1
      result = integrate_from_table(u)
      return unless result
      k2 = divide_factors(factors, factorize([u, '*', deriv(u.last, x)])) # substitute f(x)*sin(g(x)) => sin(u) du/dx dx and make sure what is left matches the rule exactly
      if free_of_var?(k2, x)
        [result, '*', unfactorize(k2)]
      end
    end
  end

  def integration_table
    @integration_table ||= expand_equations([
      "Int ln(x) dx  = x * ln(x) - x",
      "Int exp(x) dx  = exp(x)",
      "Int sin(x) dx  = -cos(x)",
      "Int cos(x) dx  = sin(x)",
      "Int tan(x) dx  = -log(cos(x))",
      "Int sinh(x) dx = cosh(x)",
      "Int cosh(x) dx = sinh(x)",
      "Int tanh(x) dx = log(cosh(x))",
      "Int (e^x) dx   = e^x",
      "Int (n^x) dx   = (n^x)/(ln n)", # should also work with y^x where y is free of x
    ])
  end

  def integrate_from_table(exp)
    translate(input: exp,
              rules: integration_table,
              patterns_func: Proc.new { |lhs, _, rhs| [lhs[1]] }, # extract f(x) from Int f(x) dx
              response_func: Proc.new { |lhs, _, rhs| rhs })
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
