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
      words = format_as_array(words.dup)
      words.first
    end

    def translate_to_expression(input)
      action_func = Proc.new do |response, variable_map|
        variable_map.each { |variable, value| response.gsub!(variable, translate_to_expression(value) || '') }
        response
      end

      translate(input: string_to_words(input), rules: student_rules, action_func: action_func) ||
      make_variable(input)
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

binding.pry
puts Student.translate_to_expression("")
