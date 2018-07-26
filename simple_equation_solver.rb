require 'pry'
require './equation_parser.rb'
require './lisp_methods.rb'

class SimpleEquationSolver
  extend ::LispMethods

  OP_INVERSES = {
    '+' => '-',
    '-' => '+',
    '*' => '/',
    '/' => '*',
    '=' => '='
  }.freeze

  class << self
    # pre-req: valid bi-exp, has one and only one equal sign, does not accept a ** b
    def isolate(equation, var)
      lhs, _, rhs = equation
      return equation if lhs == var
      return isolate([rhs, '=', lhs], var) if include_var?(rhs)

      # [- [x]] or [+ [x]]
      if lhs.size == 2
        sym, exp = lhs
        transform_sign(sym, exp, rhs, var)
      elsif lhs.size == 3
        front_exp, op, back_exp = lhs
        transform_expression(front_exp, op, back_exp, rhs, var)
      end
    end

    def transform_sign(sym, a, b, var)
      if sym == '+'
        isolate([a, '=', b])
      else
        isolate([a, '=', ['-', b]])
      end
    end

    def transform_expression(a, op, b, c, var)
      if include_var?(a)
        # X+A=B => X=B-A ; X-A=B => X=B+A ; X*A=B => X=B/A ; X/A=B => X=B*A
        isolate([a, '=', [c, inverse_op(op), b]], var)
      elsif commutative_op?(op)
        # A+X=B => X=B-A; A*X=B => X=B/A
        isolate([b, '=', [c, inverse_op(op), a]], var)
      else
        # A-X=B => X=A-B ; A/X=B => X=A/B
        isolate([b, '=', [a, op, c]], var)
      end
    end

    def get_vars(exp)
      exp = [exp] unless exp.class == Array
      exp.flatten.reject { |elem| elem.is_a?(Numeric) || ['+', '-', '*', '/', '='].include?(elem) }
    end

    def include_var?(exp)
      get_vars(exp).any?
    end

    def no_unknown?(exp)
      !include_var?(exp)
    end

    def get_if_one_unknown(exp)
      unknowns = get_vars(exp)
      unknowns.first if unknowns.size == 1
    end

    def inverse_op(op)
      i_op = OP_INVERSES[op]
      return i_op if i_op
      raise "Unrecognized operator #{op}"
    end

    def commutative_op?(op)
      ['+', '*'].include?(op)
    end

    # equation has already isolated var to lhs
    def solve_arithmetic(equation)
      lhs, _, rhs = equation
      [lhs, '=', eval(biexp_to_string(rhs))]
    end

    def string_to_biexp(string)
      EquationParser.string_to_biexp(string)
    end

    def biexp_to_string(biexp)
      EquationParser.biexp_to_string(biexp)
    end

    def solve_equation_in_strings(equation_strings)
      equations = equation_strings.map { |eq| string_to_biexp(eq) }
      solutions = solve(equations: equations)
      solutions.map { |sol| biexp_to_string(sol) }
    end

    def solve(equations: , known: [])
      unknown = nil
      equation = equations.find { |equation| unknown = get_if_one_unknown(equation) }
      return known unless unknown

      answer = solve_arithmetic(isolate(equation, unknown))
      remaining_equations = equations - [equation]
      subbed_remaining_equations = sublis(remaining_equations, answer[0], answer[2])


      if remaining_equations && subbed_remaining_equations.none? { |equation| get_if_one_unknown(equation) }
        all_rem_vars = get_vars(subbed_remaining_equations).uniq
        var_with_matched_words = all_rem_vars.map { |var| [var, num_of_matched_words(var, answer[0])] }
                                             .reject { |var, num| num == 0 }
                                             .sort_by { |var, num| num }.reverse
                                             .map(&:first)

        if var_with_matched_words.any?
          var_with_matched_words.find do |var|
            subbed_remaining_equations = sublis(subbed_remaining_equations, var, answer[2])
            subbed_remaining_equations.any? { |equation| get_if_one_unknown(equation) }
          end
        end
      end

      solve(equations: subbed_remaining_equations, known: known.push(answer))
    end

    def num_of_matched_words(test, subj)
      words_in_test = test.split(/_|'/)
      words_in_subj = subj.split(/_|'/)
      words_in_subj.size - (words_in_subj - words_in_test).size
    end
  end
end

# ses = SimpleEquationSolver
# # biexp = ses.string_to_biexp("(x + 3 ) * 9 - --- 8 /2 = 2")
# # p solved= ses.isolate(biexp, 'x')
# # p evaled = ses.solve_arithmetic(solved)
# # p ses.biexp_to_string(evaled)


# eqs = [
#   "x_something_something + 3 = 5",
#   "x_alt * y - 2 * 7 = 6"
# ]
# p ses.solve_equation_in_strings(eqs)
