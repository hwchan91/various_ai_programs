require 'pry'
require './equation_parser.rb'

class SimpleEqautionSolver
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
      return rhs if lhs == var

      return isolate([rhs, '=', lhs], var) if include_var?(rhs)

      # if not [- [x]] or [+ [x]]
      front_exp, op, back_exp = lhs

      if include_var?(front_exp)
        # X+A=B => X=B-A ; X-A=B => X=B+A ; X*A=B => X=B/A ; X/A=B => X=B*A
        isolate([front_exp, '=', [rhs, inverse_op(op), back_exp]], var)
      elsif commutative_op?(op)
        # A+X=B => X=B-A; A*X=B => X=B/A
        isolate([back_exp, '=', [rhs, inverse_op(op), front_exp]], var)
      else
        # A-X=B => X=A-B ; A/X=B => X=A/B
        isolate([back_exp, '=', [front_exp, op, rhs]], var)
      end
    end

    def get_vars(exp)
      exp = exp.flatten.join(" ") if exp.is_a?(Array)
      return [] if exp.to_s =~ /^[^a-zA-Z]+$/ # has only number and symbols
      exp.to_s.scan(/[\w\d_]+/)
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
  end
end

biexp = EquationParser.string_to_biexp("(x + 3 ) * 9 - 8 /2 = 2")
p solved= SimpleEqautionSolver.isolate(biexp, 'x')
p trans =EquationParser.biexp_to_string(solved)
p eval trans
