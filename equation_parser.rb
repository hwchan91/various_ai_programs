require 'pry'
require './rule_based_translator.rb'

class EquationParser < RuleBasedTranslator
  class << self
    attr_accessor :to_biexp_rules

    def fail
    end

    def string_to_array(string)
      return fail unless string_valid?(string)
      nested_arr, remaining = parentheses_to_array(split_equation_string(string))
      remaining.empty? ? nested_arr : fail
    end

    def string_valid?(string)
      string.scan(/\(/).size == string.scan(/\)/).size &&
      string.scan(/\=/).size <= 1
    end

    def split_equation_string(string)
      %w(x y u v).each { |var| string = string.gsub("d#{var}", "d #{var}") }
      arr = string.scan(/((\w|\d|'|_)+|\d+|\+|\-|\*|\/|\^|\=|\(|\))/)
      return if arr.empty?
      arr.map!(&:first).map! { |sym| to_numerical(sym) }
    end

    def to_numerical(sym)
      return sym.to_f if sym =~ /^\d+(\.\d+)?$/
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
      return fail if exp == fail
      result = arr_to_biexp(exp)
      check_if_biexp_valid?(result) ? result : fail
    end

    def check_if_biexp_valid?(biexp)
      return biexp if biexp.is_a?(Numeric) || biexp.is_a?(String)
      biexp.flatten.none?{|elem| elem == 'error'} &&
      biexp.flatten.any?{|elem| elem == '='}  == (biexp[1] == '=')# e.g. invalid: [ 5 * [3 = 2] ]
    end

    def arr_to_biexp(exp)
      return exp if exp.class != Array
      return arr_to_biexp(exp.first) if exp.size == 1 # i.e. [ [ 1 + 2 ] ]
      return [ exp.first, arr_to_biexp(exp.last) ] if exp.size == 2 && ["+", "-", "log", "ln", "sin", "cos", "tan", "sec", "csc", "cot", "d", "int", "exp", "sinh", "cosh", "tanh"].include?(exp.first) # i.e. [-, [x + y]]
      biexp = translate(input: exp,
                        rules: to_biexp_rules,
                        matcher_func: parser_matcher_func,
                        action_func: parser_action_func)
      return biexp if biexp

      ["error"]
    end

    def parser_matcher_func
      Proc.new { |pattern, input| PatternMatcher.new(pattern: pattern, string: input, from_end: true).solve }
    end

    def parser_action_func
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

    def biexp_to_string(exp)
      return exp.to_s unless exp.is_a? Array
      result, _ = array_to_parentheses(exp)
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

  @to_biexp_rules = expand_pattern([
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
      pattern: [%w(d ?Y+ / d ?X+)],
      responses: %w(d ?Y ?X)
    },
    {
      pattern: [%w(Int ?Y+ d ?X+)],
      responses: %w(int ?Y ?X)
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


# string = "log(x) + log(y) = log(x + y)"
# string = "Int x^2  d x"
# string = "dx/dx"
# string = "x ^ -1"
# arr = EquationParser.string_to_array(string)
# p arr
# biexp = EquationParser.string_to_biexp(string)
# p biexp
# p EquationParser.biexp_to_string(biexp)
