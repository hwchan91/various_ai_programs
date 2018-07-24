require 'pry'
require './rule_based_translator.rb'

class Student < RuleBasedTranslator
  class << self
    attr_accessor :student_rules

    def format_symbols(string)
      string = string.dup
      symbols = [".", ",", "%", "$", "+", "-", "*", "/"]

      symbols.each { |sym| string.gsub!(sym, " #{sym} ") }
      string
    end

    def remove_noise_words(words)
      words = format_as_array(words.dup)
      noise_words = ["a", "an", "the", "this", "number", "of"]

      words.reject! { |word| noise_words.include?(word) }
      words
    end

    def format_as_array(words)
      return words if words.is_a?(Array)
      words.scan(/\S+/)
    end

    def string_to_words(string)
      return if string.nil?
      remove_noise_words(format_symbols(string.downcase))
    end

    def make_variable(words)
      words = words.dup
      words.first
    end

    def translate_to_expression(input)
      action_func = Proc.new do |response, variable_map|
        variable_map.each { |variable, value| response.gsub!(variable, translate_to_expression(value) || '') }
        response
      end

      translate(input: input, rules: student_rules, action_func: action_func) ||
      make_variable(input)
    end

    def string_translate_to_expression(input)
      translate_to_expression(string_to_words(input))
    end
  end

  @student_rules = expand_rules([
    {
      pattern: "?X* .",
      responses: "?X"
    },
    {
      pattern: ["?X* . ?Y*", "?X* then ?Y*", "?X* , ?Y*"], #"?X*, ?Y*" put last because other phrase contain ','
      responses: "?X, ?Y"
    },
    {
      pattern: ["and ?X*", "then ?X*", "if ?X*"],
      responses: "?X"
    },
    {
      pattern: "find ?X*",
      responses: "to_find(?X)" # not sure
    },
    {
      pattern: ["?X* = ?Y*", "?X* equals ?Y*", "?X* is same as ?Y*",  "?X* same as ?Y*", "?X* is equal to ?Y*", "?X* is ?Y*"],
      responses: "?X = ?Y"
    },
    {
      pattern: ["?X* - ?Y*", "?X* minus ?Y*"],
      responses: "?X - ?Y"
    },
    {
      pattern: ["difference between ?X* and ?Y*", "difference ?X* and ?Y*", "?X* less than ?Y*"],
      responses: "?Y - ?X"
    },
    {
      pattern: ["?X* + ?Y*", "?X* plus ?Y*", "sum ?X* and ?Y*", "?X* greater than ?Y*"],
      responses: "?X + ?Y"
    },
    {
      pattern: ["?X* * ?Y*", "product ?X* and ?Y*", "?X* times ?Y*"],
      responses: "?X * ?Y"
    },
    {
      pattern: ["?X* / ?Y*", "?X* per ?Y*", "?X* divided by ?Y*"],
      responses: "?X / ?Y"
    },
    {
      pattern: ["half ?X*", "one half ?X*"],
      responses: "?X / 2"
    },
    {
      pattern: "twice ?X*",
      responses: "?X * 2"
    },
    {
      pattern: ["square ?X*", "?X* squared"],
      responses: "?X * ?X"
    },
    {
      pattern: ["?X* % less than ?Y*", "?X* % smaller than ?Y*"],
      responses: "?Y * (100 - ?X) / 100"
    },
    {
      pattern: ["?X* % more than ?Y*", "?X* % greater than ?Y*"],
      responses: "?Y * (100 + ?X) / 100"
    },
    {
      pattern: "?X* % ?Y*",
      responses: "?X / 100 * ?Y"
    },
    {
      pattern: "?X* and ?Y*", # put at the bottom because other phrase contain 'and'
      responses: "?X, ?Y"
    },
  ])
end


class EquationParser < RuleBasedTranslator
  class << self
    attr_accessor :to_biexp_rules

    def string_to_array(string)
      nested_arr, _ = parentheses_to_array(split_equation_string(string))
      nested_arr
    end

    def split_equation_string(string)
      arr = string.scan(/(\d+|(\w|_)+|\+|\-|\*|\/|\^|\=|\(|\))/)
      return if arr.empty?
      arr.map(&:first).map{|sym| to_numerical(sym) }
    end

    def to_numerical(sym)
      return sym.to_i if sym =~ /^\d+$/
      return sym.to_f if sym =~ /^\d+\.\d+$/
      sym
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

    def arr_to_biexp(exp)
      return exp if exp.class != Array
      return arr_to_biexp(exp.first) if exp.size == 1
      return [ exp.first, arr_to_biexp(exp.last) ] if exp.size == 2 # i.e. [-, [x + y]]

      biexp = translate(input: exp, rules: expand_rules(to_biexp_rules), action_func: action_func)
      return biexp if exp

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
      arr_to_biexp(string_to_array(string))
    end
  end

  @to_biexp_rules = expand_rules([
    {
      pattern: [%w(?X* = ?Y*)],
      responses: %w(?X = ?Y)
    },
    {
      pattern: [%w(+ ?X*)],
      responses: %w(?X)
    },
    {
      pattern: [%w(- ?X*)],
      responses: %w(- ?X)
    },
    {
      pattern: [%w(?X* + ?Y*)],
      responses: %w(?X + ?Y)
    },
    {
      pattern: [%w(?X* - ?Y*)],
      responses: %w(?X - ?Y)
    },
    {
      pattern: [%w(?X* * ?Y*)],
      responses: %w(?X * ?Y)
    },
    {
      pattern: [%w(?X* / ?Y*)],
      responses: %w(?X / ?Y)
    },
    {
      pattern: [%w(?X* ^ ?Y*)],
      responses: %w(?X ** ?Y)
    },
  ])
end

string = "5 * (3 ^ 2) / 4 = happy"
arr = EquationParser.string_to_array(string)
p arr
biexp = EquationParser.arr_to_biexp(arr)
p biexp
p EquationParser.biexp_to_string(biexp)

p EquationParser.string_to_biexp(string)

# binding.pry
# puts Student.string_translate_to_expression("x is 5")

# class EquationStandardizer
#   # assuming the equation has one and only one equal sign
#   def isolate(equation, var)
#     return unless valid_equation?(equation)

#     lhs, rhs = equation.split("=").map(&:strip)
#     return rhs if is_var?(lhs)
#     return isolate("#{rhs} = #{lhs}") if includes_var?(rhs)
#     front_exp, op, back_exp = split_expression(lhs)
#   end

#   def is_var?(equation)
#     equation[/\d+/].nil?
#   end

#   def includes_var?(equation)
#     equation[/[a-zA-Z]+/]
#   end

#   def split_expression(expression)
#     cons_product_or_divide_regex = /(\w+(\s+(\*|\/)\s+)*)+$/
#   end

#   # def valid_equation?(equation)
#   #   return if equation.scan(/=/).count > 1
#   #   return unless equation =~ /^(\(*\s*\w+\s*\)*((\s*(\+|\-|\*|\/|\=)\s*)))+\(*\w+\)*$/

#   #   # still need to account for (((equation)))
#   #   if equation[0] == "(" && equation[-1] == ")"
#   #     equation = equation[1..-2]
#   #   end

#   #   expressions = equation.split("=")
#   #   expressions.none? do |exp|
#   #     invalid = false
#   #     parentheses = exp.scan(/\(|\)/)
#   #     open_parentheses_count = parentheses.select { |sym| sym == "(" }.count
#   #     invalid = true unless open_parentheses_count == parentheses.count / 2

#   #     level_count = 0
#   #     parentheses.each do |sym|
#   #       next if invalid
#   #       level_count += 1 if sym == "("
#   #       level_count -= 1 if sym == ")"
#   #       invalid = true if level_count < 0
#   #     end
#   #     invalid
#   #   end
#   # end
# end
