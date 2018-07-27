require 'pry'
require './rule_based_translator.rb'
require './lisp_methods.rb'
require './simple_equation_solver.rb'

class Student < RuleBasedTranslator
  extend ::LispMethods

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
      if [words].flatten(1).first =~ /^\d+(\.\d+)?$/
        [words].flatten.first.to_f
      else
        words.join("_")
      end
    end

    def translate_to_expression(input)
      translate(input: input, rules: student_rules, action_func: action_func) ||
      make_variable(input)
    end

    def action_func
      Proc.new do |response, variable_map|
        variable_map.each do |variable, value|
          response = sublis(response, variable, translate_to_expression(value))
        end
        response
      end
    end

    def string_translate_to_expression(input)
      translate_to_expression(string_to_words(input))
    end

    def create_list_of_equations(biexp)
      if biexp.nil?
        []
      elsif biexp.class != Array || %w(+ - * / =).include?(biexp[1])
        [biexp]
      else
        create_list_of_equations(biexp[0]) +  create_list_of_equations(biexp[1])
      end
    end

    def biexp_to_string(biexp)
      EquationParser.biexp_to_string(biexp)
    end

    def solve_worded_question(string)
      expressions = create_list_of_equations(string_translate_to_expression(string))
      solutions = SimpleEquationSolver.solve_equation(expressions)
      puts "The equations to solve are:"
      expressions.each { |exp| puts biexp_to_string(exp) }
      p "The solutions are:"
      solutions.each { |exp| puts exp }
      nil
    end
  end

  @student_rules = expand_rules([
    {
      pattern: ["?X+ .",  "?X+ ,"],
      responses: "?X"
    },
    {
      pattern: ["?X+ . ?Y+", "?X+ then ?Y+", "?X+ , ?Y+"], #"?X+, ?Y+" put last because other phrase contain ','
      responses: %w(?X ?Y)
    },
    {
      pattern: ["then ?X+", "if ?X+", "and ?X+"],
      responses: "?X"
    },
    {
      pattern: [ ["find", ["?+", "?X", "(?X - %w(difference sum product)).size == ?X.size"], "and", "?Y+"] ],
      responses: [%w(to_find_1 = ?X), %w(to_find_2 = ?Y)]
    },
    {
      pattern: "find ?X+",
      responses: %w(to_find = ?X)
    },
    {
      pattern: [ [["?+", "?X", "(?X - %w(difference sum product)).size == ?X.size"], 'and', "?Y+" ] ],
      responses: %w(?X ?Y)
    },
    {
      pattern: ["?X+ = ?Y+", "?X+ equals ?Y+", "?X+ is same as ?Y+",  "?X+ same as ?Y+", "?X+ is equal to ?Y+", "?X+ is ?Y+"],
      responses: %w(?X = ?Y)
    },
    {
      pattern: ["?X+ - ?Y+", "?X+ minus ?Y+"],
      responses: %w(?X - ?Y)
    },
    {
      pattern: ["difference between ?X+ and ?Y+", "difference ?X+ and ?Y+", "?X+ less than ?Y+"],
      responses: %w(?Y - ?X)
    },
    {
      pattern: ["?X+ + ?Y+", "?X+ plus ?Y+", "sum ?X+ and ?Y+", "?X+ greater than ?Y+"],
      responses: %w(?X + ?Y)
    },
    {
      pattern: ["?X+ * ?Y+", "product ?X+ and ?Y+", "?X+ times ?Y+"],
      responses: %w(?X * ?Y)
    },
    {
      pattern: ["?X+ / ?Y+", "?X+ per ?Y+", "?X+ divided by ?Y+"],
      responses: %w(?X / ?Y)
    },
    {
      pattern: ["half ?X+", "one half ?X+"],
      responses: ["?X", "/", 2.0]
    },
    {
      pattern: "twice ?X+",
      responses: ["?X", "*", 2.0]
    },
    {
      pattern: ["square ?X+", "?X+ squared"],
      responses: ["?X", "*", "?X"]
    },
    {
      pattern: ["?X+ % less than ?Y+", "?X+ % smaller than ?Y+"],
      responses: ["?Y", "*", [[100.0, "-", "?X"], "/", 100.0]]
    },
    {
      pattern: ["?X+ % more than ?Y+", "?X+ % greater than ?Y+"],
      responses: ["?Y", "*", [[100.0, "+", "?X"], "/", 100.0]]
    },
    {
      pattern: "?X+ % ?Y+",
      responses: [["?X", "/",  100.0], "*", "?Y"]
    },
  ])
end

# p Student.string_translate_to_expression("x is 5, y is 10, find x and y")
# p Student.string_translate_to_expression("x is 5 and y is 10")
# biexp = Student.string_translate_to_expression("x is the sum of 5 and 3, y")
# binding.pry

puts Student.solve_worded_question("If the number of customers Tom gets is twice the square of 20% of the number of his advertisements, and the number of advertisements is 45, then what is the amount of customers?")
