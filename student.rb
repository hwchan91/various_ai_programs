require 'pry'
require './rule_based_translator.rb'
require './simple_equation_solver.rb'

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
      # words.first
      words.join("_")
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

    def solve_worded_question(string)
      expressions = string_translate_to_expression(string).split(",").map(&:strip).reject{|exp| exp.start_with?('to_find') || exp.empty? }
      solutions = SimpleEquationSolver.solve_equation_in_strings(expressions)
      puts "The equations to solve are:"
      expressions.each { |exp| puts exp }
      p "The solutions are:"
      solutions.each { |exp| puts exp }
      nil
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

# binding.pry
# puts Student.string_translate_to_expression("rectangle's width is 5")

puts Student.solve_worded_question("If the number of customers Tom gets is twice the square of 20% of the number of his advertisements, and the number of advertisements is 45, then what is the amount of customers?")

puts Student.solve_worded_question("If Mary's age is 5 greater than Tom, Tom is half of Jane's, and Jane is 10. What is the sum of Mary and Tom's ages?")
