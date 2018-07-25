require 'pry'
require './rule_based_translator.rb'

class EquationParser < RuleBasedTranslator
  class << self
    attr_accessor :to_biexp_rules

    def string_to_array(string)
      return "error" unless string_valid?(string)
      nested_arr, remaining = parentheses_to_array(split_equation_string(string))
      remaining.empty? ? nested_arr : "error"
    end

    def string_valid?(string)
      string.scan(/\(/).size == string.scan(/\)/).size &&
      string.scan(/\=/).size <= 1
    end

    def split_equation_string(string)
      arr = string.scan(/((\w|\d|_)+|\d+|\+|\-|\*|\/|\^|\=|\(|\))/)
      return if arr.empty?
      arr.map(&:first).map{|sym| to_numerical(sym) }
    end

    def to_numerical(sym)
      return sym.to_i if sym =~ /^\d+$/
      return sym.to_f if sym =~ /^\d+\.\d+$/
      sym
    end

    def parentheses_to_array(obj, result = [])
      return [result, []] if obj.empty?

      if obj[0] == ")"
        return [result, obj[1..-1]]
      elsif obj[0] !=  "("
        result << obj[0]
        parentheses_to_array(obj[1..-1], result)
      else
        new_array, remaining = parentheses_to_array(obj[1..-1])
        result << new_array
        parentheses_to_array(remaining, result)
      end
    end

    def arr_to_biexp_checked(exp)
      return ["error"] if exp == 'error'
      result = arr_to_biexp(exp)
      check_if_biexp_valid?(result) ? result : ["error"]
    end

    def check_if_biexp_valid?(biexp)
      biexp.flatten.none?{|elem| elem == 'error'} &&
      biexp.flatten.any?{|elem| elem == '='}  == (biexp[1] == '=')# e.g. invalid: [ 5 * [3 = 2] ]
    end

    def arr_to_biexp(exp)
      return exp if exp.class != Array
      return arr_to_biexp(exp.first) if exp.size == 1 # i.e. [ [ 1 + 2 ] ]
      return [ exp.first, arr_to_biexp(exp.last) ] if exp.size == 2  && ["+", "-"].include?(exp.first) # i.e. [-, [x + y]]
      biexp = translate(input: exp, rules: expand_rules(to_biexp_rules), action_func: action_func)
      return biexp if biexp

      ["error"]
    end

    def action_func
      Proc.new do |response, variable_map|
        variable_map.each do |variable, value|
          response.map! { |elem| elem == variable ?  arr_to_biexp(value) : elem }
        end
        response
      end
    end

    def string_to_biexp(string)
      arr_to_biexp_checked(string_to_array(string))
    end

    def biexp_to_string(arr)
      result, _ = array_to_parentheses(arr)
      result.flatten.join(" ")
    end

    def array_to_parentheses(obj, result = [])
      return [result, []] if obj.empty?

      if obj[0].class == Array
        result << "("
        result << biexp_to_string(obj[0])
        result << ")"
        array_to_parentheses(obj[1..-1], result)
      else
        result << obj[0]
        array_to_parentheses(obj[1..-1], result)
      end
    end
  end

  @to_biexp_rules = expand_rules([
    {
      pattern: [%w(?X+ = ?Y+)],
      responses: %w(?X = ?Y)
    },
    {
      pattern: [%w(+ ?X+)],
      responses: %w(?X)
    },
    {
      pattern: [%w(- ?X+)],
      responses: %w(- ?X)
    },
    {
      pattern: [ [ ["?+", "?X", "!['*', '^', '/'].include?(?X.last)"], "+", "?Y+"] ],
      responses: %w(?X + ?Y)
    },
    {
      pattern: [ [ ["?+", "?X", "!['*', '^', '/'].include?(?X.last)"], "-", "?Y+"] ],
      responses: %w(?X - ?Y)
    },
    {
      pattern: [%w(?X+ * ?Y+)],
      responses: %w(?X * ?Y)
    },
    {
      pattern: [%w(?X+ / ?Y+)],
      responses: %w(?X / ?Y)
    },
    {
      pattern: [%w(?X+ ^ ?Y+)],
      responses: %w(?X ** ?Y)
    },
  ])
end

# string = "(3 + ----2) * 5 = 25 * -var"
# arr = EquationParser.string_to_array(string)
# p arr
# biexp = EquationParser.string_to_biexp(string)
# p biexp
# p EquationParser.biexp_to_string(biexp)